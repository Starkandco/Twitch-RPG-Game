extends Control

# Your client id. You can share this publicly. Default is my own client_id.
# Please do not ship your project with my client_id, but feel free to test with it.
# Visit https://dev.twitch.tv/console/apps/create to create a new application.
# You can then find your client id at the bottom of the application console.
# DO NOT SHARE THE CLIENT SECRET. If you do, regenerate it.
@export var client_id : String = "m15sgvbjxqqgxi4yqoxkw1ny4mg3hv"
# The name of the channel we want to connect to.
@export var channel : String
# The username of the bot account.
@export var username : String

var id : TwitchIDConnection
var api : TwitchAPIConnection
var irc : TwitchIRCConnection

var cmd_handler : GIFTCommandHandler = GIFTCommandHandler.new()

var iconloader : TwitchIconDownloader

var parties = {}
var players = []
var chatters = {}

func _ready() -> void:
	# We will login using the Implicit Grant Flow, which only requires a client_id.
	# Alternatively, you can use the Authorization Code Grant Flow or the Client Credentials Grant Flow.
	# Note that the Client Credentials Grant Flow will only return an AppAccessToken, which can not be used
	# for the majority of the Twitch API or to join a chat room.
	var auth : ImplicitGrantFlow = ImplicitGrantFlow.new()
	# For the auth to work, we need to poll it regularly.
	get_tree().process_frame.connect(auth.poll) # You can also use a timer if you don't want to poll on every frame.

	# Next, we actually get our token to authenticate. We want to be able to read and write messages,
	# so we request the required scopes. See https://dev.twitch.tv/docs/authentication/scopes/#twitch-access-token-scopes
	var token : UserAccessToken = await(auth.login(client_id, ["chat:read", "chat:edit"]))
	if (token == null):
		# Authentication failed. Abort.
		return

	# Store the token in the ID connection, create all other connections.
	id = TwitchIDConnection.new(token)
	irc = TwitchIRCConnection.new(id)
	api = TwitchAPIConnection.new(id)
	iconloader = TwitchIconDownloader.new(api)
	# For everything to work, the id connection has to be polled regularly.
	get_tree().process_frame.connect(id.poll)

	# Connect to the Twitch chat.
	if(!await(irc.connect_to_irc(username))):
		# Authentication failed. Abort.
		return
	# Request the capabilities. By default only twitch.tv/commands and twitch.tv/tags are used.
	# Refer to https://dev.twitch.tv/docs/irc/capabilities/ for all available capapbilities.
	irc.request_capabilities()
	# Join the channel specified in the exported 'channel' variable.
	irc.join_channel(channel)

	cmd_handler.add_command("join", _join)
	cmd_handler.add_command("leave", _leave)
	
	irc.chat_message.connect(cmd_handler.handle_command)
	irc.whisper_message.connect(cmd_handler.handle_command.bind(true))

	irc.chat_message.connect(_custom_handle_command)
	irc.whisper_message.connect(_custom_handle_command)

func _custom_handle_command(sender_data, message):
	var user = sender_data.user
	#If this is the first message for the user
	if !chatters.has(user):
		#Array - 0 is count of messages, 1, 2, 3 etc. are a list of up to 9 messages
		chatters[user] = [1, Time.get_ticks_msec()]
	else:
		chatters[user].append(Time.get_ticks_msec())
		chatters[user][0] += 1
		#Once ten messages have passed
		if chatters[user][0] >= 10:
			#If this was all within one second
			if chatters[user][10] - chatters[user][1] <= 1000:
				chatters[user][0] -= 1 
				chatters[user].pop_at(1)
			else:
				#They're not banned yet - let's remove the first message in the list 
				#They haven't done all 10 messages in 1 second
				chatters[user][0] -= 1 # 1 less count
				chatters[user].pop_at(1) # remove timere
		
	#Drop out here if player doesn't exist
	if !players.has(user): return
	var callable_str = ""
	var split_message = message.to_lower().rsplit(" ", false)
	var new_callable
	var collect_params = false
	var params = []
	var count = 0
	for part in split_message:
		if count == 0 and part.begins_with("_"):
			return
		count += 1
		if collect_params:
			params.append(part)
			continue 
		if callable_str != "":
			callable_str += "_"
		callable_str += part
		new_callable = Callable(self, callable_str)
		if new_callable.is_valid():
			collect_params = true
			continue
		elif count == split_message.size():
			callable_str = "NA"
	if callable_str in %WhiteList.whitelist_names["GIFT"]:
		params.insert(0, user)
		if params.size() >= %WhiteList.whitelist_params["GIFT"][%WhiteList.whitelist_names["GIFT"].find(callable_str)][0] and params.size() <= %WhiteList.whitelist_params["GIFT"][%WhiteList.whitelist_names["GIFT"].find(callable_str)][1]:
			_check_params_and_call(params, new_callable)
	else:
		callable_str = ""
		var player = _get_player_entity(user)
		if !player: return
		for part in split_message:
			count += 1
			if collect_params:
				params.append(part)
				continue 
			if callable_str != "":
				callable_str += "_"
			callable_str += part
			new_callable = Callable(player, callable_str)
			if new_callable.is_valid():
				collect_params = true
				continue
			elif count == split_message.size():
				callable_str = "NA"
		
		if callable_str in %WhiteList.whitelist_names["Player"]:
			if params.size() >= %WhiteList.whitelist_params["Player"][%WhiteList.whitelist_names["Player"].find(callable_str)][0] and params.size() <= %WhiteList.whitelist_params["Player"][%WhiteList.whitelist_names["Player"].find(callable_str)][1]:
				_check_params_and_call(params, new_callable)
		else:
			player._say(message)

func _check_params_and_call(params, new_callable):
	match params.size():
		0:
			new_callable.call()
		1:
			new_callable.call(params[0])
		2:
			new_callable.call(params[0], params[1])
		3:
			new_callable.call(params[0], params[1], params[2])
		4:
			new_callable.call(params[0], params[1], params[2], params[3])
		5:
			new_callable.call(params[0], params[1], params[2], params[3], params[4])

func _join(cmd_info: CommandInfo) -> void:
	var user = cmd_info.sender_data.user
	if !players.has(user):
		players.append(user)

func _leave(cmd_info: CommandInfo) -> void:
	var user = cmd_info.sender_data.user
	if players.has(user):
		if parties.has(user):
			var player = _get_player_entity(user)
			if player:
				player.get_parent().get_parent().player_leave(user)
			parties.erase(user)
		else:
			for party in parties:
				for member in parties[party]:
					if str(parties[party][member]) == user:
						parties[party].erase(member)
						parties[party]["Members"] -= 1
						parties[party]["UI"].get_child(1).text = str(parties[party]["Members"]) + " / 6"
						parties[party] = _sort_party(parties[party])
			var player = _get_player_entity(user)
			if player:
				player.get_parent().get_parent().player_leave(user)
	players.erase(user)

func join_party(user, second_arg) -> void:
	if players.has(user) and !_get_player_entity(user):
		var leader_name = second_arg.to_lower()
		if parties.has(leader_name) and parties[leader_name]["Members"] < 5:
			parties[leader_name]["member" + str(parties[leader_name]["Members"])] = user
			parties[leader_name]["Members"] += 1
			parties[leader_name]["UI"].get_child(1).text = str(parties[leader_name]["Members"]) + " / 6"

func _sort_party(party):
	var members = [false, false, false, false, false]
	for member in range(party["Members"]):
		if party.has("member" + str(member + 1)):
			members[member] = true
	for x in range(5):
		if !members[x] and x < 4 and members[x + 1]:
			party["member" + str(x)] = party["member" + str(x + 1)]
			party.erase("member" + str(x + 1))
			members[x + 1] = false
		elif !members[x] and x < 3 and members[x + 2]:
			party["member" + str(x)] = party["member" + str(x + 2)]
			party.erase("member" + str(x + 2))
			members[x + 2] = false
		elif !members[x] and x < 2 and members[x + 3]:
			party["member" + str(x)] = party["member" + str(x + 3)]
			party.erase("member" + str(x + 3))
			members[x + 3] = false
		elif !members[x] and x < 1 and members[x + 4]:
			party["member" + str(x)] = party["member" + str(x + 4)]
			party.erase("member" + str(x + 4))
			members[x + 4] = false
	return party


func quit_party(user) -> void:
	if !parties.has(user) and players.has(user) and !_get_player_entity(user):
		var found = false
		for party in parties:
			for member in parties[party]:
				if str(parties[party][member]) == user:
					parties[party].erase(member)
					parties[party]["Members"] -= 1
					parties[party] = _sort_party(parties[party])
					parties[party]["UI"].get_child(1).text = str(parties[party]["Members"]) + " / 6"
					return

func start_party(user) -> void:
	if players.has(user) and !parties.has(user):
		for party in parties:
			for member in parties[party]:
				if str(parties[party][member]) == user:
					return
		parties[user] = {"Leader": user, "Started": false, "Members": 1}
		var hbox = HBoxContainer.new()
		var leader = Label.new()
		var count = Label.new()
		hbox.add_theme_constant_override("separation", 10)
		leader.text = user
		count.text = "1 / 6"
		leader.add_theme_font_size_override("font_size", 32)
		count.add_theme_font_size_override("font_size", 32)
		%PartyList.add_child(hbox)
		hbox.add_child(leader)
		hbox.add_child(count)
		parties[user]["UI"] = hbox
	
func change_colour(user, arg) -> void:
	if players.has(user):
		var player = _get_player_entity(user)
		if player:
			var new_colour = Color(arg)
			if new_colour != Color():
				player._set_colour(arg)

func change_ui(user, arg0 = Color.VIOLET, arg1 = Color.YELLOW, arg2 = Color.DARK_RED, arg3 = Color.CADET_BLUE) -> void:
	if players.has(user):
		var player = _get_player_entity(user)
		if player:
			var new_a = Color(arg0)
			var new_b = Color(arg1)
			var new_c = Color(arg2)
			var new_d = Color(arg3)
			if new_a != Color() or new_b != Color() or new_c != Color() or new_d != Color():
				if parties.has(user):
					player._change_UI(arg0, arg1, arg2, arg3)
				else:
					player._update_colours(arg0, arg1, arg2, arg3)

func new_save(user) -> void:
	if not FileAccess.file_exists("res://data/"+user+".save"):
		return # Error! We don't have a save to load.
	var dir = DirAccess.open("res://data/")
	dir.remove(user+".save")

func start_adventure(user) -> void:
	if players.has(user) and parties.has(user):
		if !parties[user]["Started"]:
			parties[user]["Started"] = true
			parties[user]["UI"].queue_free()
			parties[user].erase("UI")
			parties[user].erase("Members")
			get_parent().get_node("SubViewportContainer/OverallGameSubViewport/MarginContainer/ChatterGridContainer").party_start(parties[user])

func _get_player_entity(internal) -> Player:
	for player in get_tree().get_nodes_in_group("Player"):
		if player.user == internal:
			return player
	return null
