extends Node2D

class_name GameScene

@onready var saving_node = get_parent().get_node("Saving")
@export var player_scene: PackedScene

@onready var objects: Array[PackedScene] = create_array()

@export var string_name: String

var party_leader
var scene_players = {}
var player_position = 0
var limiter = false
var count = 1

func create_array() -> Array[PackedScene]:
	var file_path = get_scene_file_path().rsplit("/", false, 1)
	var dir = DirAccess.open(file_path[0])
	var temp_dir: Array[PackedScene] = []
	dir.list_dir_begin()
	while true:
		#get_next() returns a string so this can be used to load the difficulties into an array.
		var file_name = dir.get_next()
		if file_name == "":
			#break the while loop when get_next() returns ""
			break
		elif !file_name.begins_with(".") and file_name != file_path[1]:
			temp_dir.append(load(file_path[0] + "/" + file_name))
	dir.list_dir_end()
	return temp_dir

func _physics_process(_delta):
	if party_leader:
		player_position = party_leader.position.x
		if !limiter and roundi(player_position) / 500 > count:
			count += 1
			limiter = true
			var object = objects[randi_range(0, objects.size() - 1)].instantiate()
			$Obstacles.add_child(object)
			object.position.x = player_position + 2000
		elif limiter:
			limiter = false

func player_join(user):
	var new_player
	if scene_players.size() == 0:
		new_player = saving_node.load_game(user)
		if !new_player:
			new_player = player_scene.instantiate()
			new_player.user = user
		party_leader = new_player
		party_leader.dead.connect(game_over)
		new_player.is_leader = true
		$Players.add_child(new_player)
		new_player.z_index = 10
	else:
		new_player = saving_node.load_game(user)
		if !new_player:
			new_player = player_scene.instantiate()
			new_player.user = user
		$Players.add_child(new_player)
		new_player.position.x = party_leader.position.x + (scene_players.size() * 20)
		new_player.z_index = 10 - scene_players.size()
		for player in scene_players.keys():
			new_player.interaction_started.connect(scene_players[player]._stop)
	scene_players[user] = new_player

func player_leave(user):
	if user == party_leader.user:
		saving_node.save_nodes()
		get_parent().get_parent().queue_free()
	else:
		scene_players[user].queue_free()
		scene_players.erase(user)

func game_over():
	get_parent().get_node("GameUI/GameOverScreen").visible = true
	get_tree().create_tween().tween_callback(free_self.bind(party_leader.user)).set_delay(10)

func free_self(user):
	get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_node("BackgroundRect")._leave({"sender_data":{"user":user}})
	
