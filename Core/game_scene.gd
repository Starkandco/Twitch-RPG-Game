extends Node2D

class_name GameScene

@onready var saving_node = get_parent().get_node("Saving")
@export var player_scene: PackedScene
var party_leader
var scene_players = {}

func player_join(user):
	var new_player
	if scene_players.size() == 0:
		new_player = saving_node.load_game(user)
		if !new_player:
			new_player = player_scene.instantiate()
			new_player.user = user
		party_leader = new_player
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
			new_player.interaction_started.connect(scene_players[player].stop)
	scene_players[user] = new_player

func player_leave(user):
	saving_node.save_nodes()
	scene_players[user].queue_free()
	scene_players.erase(user)
	if scene_players.size() == 0:
		get_parent().get_parent().queue_free()
