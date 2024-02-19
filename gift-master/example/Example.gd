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

var secret = "lux38p10taxf10mhd5dlib4mkhwfv3"

var id : TwitchIDConnection
var api : TwitchAPIConnection
var irc : TwitchIRCConnection

var cmd_handler : GIFTCommandHandler = GIFTCommandHandler.new()

var parties = {}
var players = []
var chatters = {}
var black_list = []
var scopes = ["chat:read", "chat:edit", "channel:moderate", "user:manage:whispers"]
var auth : AuthorizationCodeGrantFlow 

var help_message_1 = "\"start party\" - start a new party. \"join party <user>\" - join a party. \"quit party\" - leave the party you're in (before game start)"
var help_message_2 = "\"start adventure\" - only party leaders. \"new save\" - reset save file for your character (Are you sure..?)"
var help_message_3 = "\"change colour <colour_name e.g. red / colour_hex e.g. 123456>\" - Check Godots documentation on Color for colour keywords. \"change UI <0 to 4 colours>\" - Top left clockwise. Only applies leader colours. \n"
var help_message_4 = "\"gain skill <new_skill> <replace_skill>\"/ \"dismiss skill <new_skill>\" - Select a new skill or dismiss it (lost forever). NB: CASE SENSITIVE e.g. write impale as Impale."
var help_message_5 = "All other commands as appear in game."


func _ready() -> void:
	# We will login using the Implicit Grant Flow, which only requires a client_id.
	# Alternatively, you can use the Authorization Code Grant Flow or the Client Credentials Grant Flow.
	# Note that the Client Credentials Grant Flow will only return an AppAccessToken, which can not be used
	# for the majority of the Twitch API or to join a chat room.
	auth = AuthorizationCodeGrantFlow.new()
	# For the auth to work, we need to poll it regularly.
	get_tree().process_frame.connect(auth.poll) # You can also use a timer if you don't want to poll on every frame.
		
	# Next, we actually get our token to authenticate. We want to be able to read and write messages,
	# so we request the required scopes. See https://dev.twitch.tv/docs/authentication/scopes/#twitch-access-token-scopes
	var token : UserAccessToken = await(auth.login(client_id, secret, "", scopes))
	if (token == null):
		# Authentication failed. Abort.
		return

	# Store the token in the ID connection, create all other connections.
	id = TwitchIDConnection.new(token)
	irc = TwitchIRCConnection.new(id)
	api = TwitchAPIConnection.new(id)
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
	cmd_handler.add_command("help", _help)
	
	irc.chat_message.connect(cmd_handler.handle_command)
	irc.whisper_message.connect(cmd_handler.handle_command.bind(true))

	irc.chat_message.connect(_custom_handle_command)
	irc.whisper_message.connect(_custom_handle_command)
	%HelpTimer.timeout.connect(%HelpTimer.stop)


func _help(cmd_info):
	var user_ids = await api.get_users_by_name([cmd_info.sender_data.user])
	api.send_whisper("1038677579", user_ids["data"][0]["id"], help_message_1)
	await get_tree().create_timer(3).timeout
	api.send_whisper("1038677579", user_ids["data"][0]["id"], help_message_2)
	await get_tree().create_timer(3).timeout
	api.send_whisper("1038677579", user_ids["data"][0]["id"], help_message_3)
	await get_tree().create_timer(3).timeout
	api.send_whisper("1038677579", user_ids["data"][0]["id"], help_message_4)
	await get_tree().create_timer(3).timeout
	api.send_whisper("1038677579", user_ids["data"][0]["id"], help_message_5)
		
	
func _custom_handle_command(sender_data, message):
	var user = sender_data.user
	if user in black_list: return
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
				black_list.append(user)
			else:
				#They're not banned yet - let's remove the first message in the list 
				#They haven't done all 10 messages in 1 second
				chatters[user][0] -= 1 # 1 less count
				chatters[user].pop_at(1) # remove timere
		
	#Drop out here if player doesn't exist
	if !players.has(user): return
	var callable_str = ""
	var split_message = message.rsplit(" ", false)
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
		callable_str += part.to_lower()
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
			callable_str += part.to_lower()
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
		6:
			new_callable.call(params[0], params[1], params[2], params[3], params[4], params[5])

func _join(cmd_info) -> void:
	var user = cmd_info.sender_data.user
	if !players.has(user):
		players.append(user)

func _leave(cmd_info) -> void:
	var user = cmd_info.sender_data.user
	if players.has(user):
		if parties.has(user):
			var player = _get_player_entity(user)
			if player:
				player.get_parent().get_parent().player_leave(user)
			elif parties[user].has("UI"):
				parties[user]["UI"].queue_free()
			parties.erase(user)
		else:
			for party in parties:
				for member in parties[party]:
					if str(parties[party][member]) == user:
						parties[party].erase(member)
						parties[party]["Members"] -= 1 #TODO when player leaves active party this falls over
						parties[party]["UI"].get_child(1).text = str(parties[party]["Members"]) + " / 6"
						parties[party] = _sort_party(parties[party])
			var player = _get_player_entity(user)
			if player:
				player.get_parent().get_parent().player_leave(user)
		players.erase(user)

func join_party(user, second_arg) -> void:
	if players.has(user) and !_get_player_entity(user):
		for party in parties:
			for member in parties[party]:
				if str(parties[party][member]) == user:
					return
		var leader_name = second_arg.to_lower()
		if parties.has(leader_name) and !_get_player_entity(leader_name) and parties[leader_name]["Members"] < 5:
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
			if new_colour != Color() or arg.to_lower() == "black" or arg == "000000":
				player._set_colour(arg)

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


func _on_timer_timeout():
	auth.poll()
