extends Node

func save_nodes():
	var players = get_parent().get_child(1).get_node("Players").get_children()
	for node in players:
		var save_game = FileAccess.open("res://data/"+node.user+".save", FileAccess.WRITE)
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue
			
		if !node.has_method("_return_dict_for_save"):
			print("persistent node '%s' is missing a return_dict_for_save() function, skipped" % node.name)
			continue
		
		var node_data = node._return_dict_for_save()
		var json_string = JSON.stringify(node_data)
		save_game.store_line(json_string)

func save_player(user):
	var players = get_parent().get_child(1).get_node("Players").get_children()
	for node in players:
		if node.user != user: continue
		var save_game = FileAccess.open("res://data/"+node.user+".save", FileAccess.WRITE)
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue
			
		if !node.has_method("_return_dict_for_save"):
			print("persistent node '%s' is missing a return_dict_for_save() function, skipped" % node.name)
			continue
		
		var node_data = node._return_dict_for_save()
		var json_string = JSON.stringify(node_data)
		save_game.store_line(json_string)
		return

func load_game(user):
	if not FileAccess.file_exists("res://data/"+user+".save"):
		return # Error! We don't have a save to load.
	
	var save_game = FileAccess.open("res://data/"+user+".save", FileAccess.READ)
	while save_game.get_position() < save_game.get_length():
		var json_string = save_game.get_line()
		
		var json = JSON.new()
		
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue
			
		var node_data = json.get_data()
		
		var new_object = load(node_data["filename"]).instantiate()
		for i in node_data.keys():
			if i == "filename":
				continue
			new_object.set(i, node_data[i])
		return new_object

