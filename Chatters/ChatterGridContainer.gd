extends GridContainer

@export var game_scene: PackedScene 

func party_start(party):
	if get_child_count() < 6:
		var new_game = game_scene.instantiate()
		add_child(new_game)
		update_columns()
		for key in party.keys():
			if key == "Leader":
				new_game.get_child(0).get_child(1).player_join(party[key])
		for key in party.keys():
			if !key in ["Leader", "Started", "UI"]:
				new_game.get_child(0).get_child(1).player_join(party[key])

func party_end(index):
	if index in range(get_child_count()):
		var child = get_child(index)
		var instanced_game_scene = child.get_node("ChatterGameSubViewport/GameScene")
		var parties = get_parent().get_parent().get_parent().get_parent().get_node("BackgroundRect").parties
		for player in instanced_game_scene.scene_players:
			instanced_game_scene.player_leave(player)
			for key in parties.keys():
				if key == player:
					parties.erase(key) 
		remove_child(child)
		child.queue_free()
		while child.is_queued_for_deletion():
			await get_tree().process_frame
		update_columns()

func update_columns():
	var children = get_child_count()
	if children == 1:
		columns = 1
	elif children >= 2 and children <= 4:
		columns = 2
	else:
		columns = 3
