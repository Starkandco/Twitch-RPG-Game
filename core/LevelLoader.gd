extends Node

@onready var level_array = create_array()

func create_array() -> Array[PackedScene]:
	var file_path = "res://levels/"
	var dir = DirAccess.open(file_path)
	var temp_dir: Array[PackedScene] = []
	dir.list_dir_begin()
	var count = 0
	while true:
		#get_next() returns a string so this can be used to load the difficulties into an array.
		var folder_name = dir.get_next()
		if folder_name == "":
			#break the while loop when get_next() returns ""
			break
		elif !folder_name.begins_with("."):
			count += 1
	dir.list_dir_end()
	for x in range(count):
		var folder_path = file_path + "level_" + str(x + 1)
		var folder_dir = DirAccess.open(folder_path)
		folder_dir.list_dir_begin()
		while true:
			#get_next() returns a string so this can be used to load the difficulties into an array.
			var file_name = folder_dir.get_next()
			if file_name == "":
				#break the while loop when get_next() returns ""
				break
			elif !file_name.begins_with(".") and file_name == "level_" + str(x + 1) + ".tscn":
				temp_dir.append(load(folder_path + "/" + file_name))
		dir.list_dir_end()
	return temp_dir
