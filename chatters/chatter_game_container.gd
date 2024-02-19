extends GridContainer

@export var chatter_container: PackedScene

func party_start(party):
	if get_child_count() < 6:
		var new_container = chatter_container.instantiate()
		var saver = new_container.get_node("ChatterGameSubViewport/Saving")
		var loader = new_container.get_node("ChatterGameSubViewport/LevelLoader")
		add_child(new_container)
		var temp
		for key in party.keys():
			if key == "Leader":
				temp = saver.load_game(party[key])
		var new_game
		if temp:
			var level_to_load = temp.level / 5
			new_game =  loader.level_array[level_to_load if level_to_load < loader.level_array.size() - 1 else loader.level_array.size() - 1].instantiate()
		else:
			new_game = loader.level_array[0].instantiate()
		saver.add_sibling(new_game)
		update_columns()
		for key in party.keys():
			if key == "Leader":
				new_game.player_join(party[key])
		for key in party.keys():
			if key.begins_with("member"):
				new_game.player_join(party[key])


func update_columns():
	var children = get_child_count()
	if children == 1:
		columns = 1
	elif children >= 2 and children <= 4:
		columns = 2
	else:
		columns = 3


func _on_child_exiting_tree(node):
	while is_instance_valid(node):
		await get_tree().process_frame
	update_columns()
