extends Node

var gift_script_path = "res://gift-master/example/Example.gd"
var player_script_path = "res://Chatters/Chatter/Player.gd"
var whitelist_names = {"GIFT": [], "Player": []}
var whitelist_params = {"GIFT": [], "Player": []}

func _ready():
	if not FileAccess.file_exists(gift_script_path):
		return # Error! We don't have a save to load.
	
	var gift_script = FileAccess.open(gift_script_path, FileAccess.READ)
	while gift_script.get_position() < gift_script.get_length():
		var code_line: String = gift_script.get_line()
		if code_line.contains("func") and code_line.contains("user"):
			var function_name = code_line.split(" ")[1].split("(")[0]
			var params
			if code_line.contains("()"):
				params = 0
			else:
				params = code_line.split(" ")[1].split(",").size()
			if function_name.begins_with("_"): continue
			whitelist_names["GIFT"].append(function_name)
			whitelist_params["GIFT"].append(params)
	
	if not FileAccess.file_exists(player_script_path):
		return # Error! We don't have a save to load.
	
	var player_script = FileAccess.open(player_script_path, FileAccess.READ)
	while player_script.get_position() < player_script.get_length():
		var code_line: String = player_script.get_line()
		if code_line.contains("func"):
			var function_name = code_line.split(" ")[1].split("(")[0]
			var params
			if code_line.contains("()"):
				params = 0
			else:
				params = code_line.split(" ")[1].split(",").size() 
			if  function_name.begins_with("_"): continue
			whitelist_names["Player"].append(function_name)
			whitelist_params["Player"].append(params)
