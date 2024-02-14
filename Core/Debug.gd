extends Window

@onready var twitch_node = $"../BackgroundRect"

func _process(_delta):
	if Input.is_action_just_pressed("debug"):
		visible = !visible

func _on_button_pressed():
	if !twitch_node.players.has("starkandco"):
		twitch_node.players.append("starkandco")
	
func _on_button_2_pressed():
	twitch_node._custom_handle_command({"user": "starkandco"}, "start party")

func _on_button_3_pressed():
	twitch_node._custom_handle_command({"user": "starkandco"}, "start adventure")

func _on_button_4_pressed():
	var player = twitch_node._get_player_entity("starkandco")
	if player:
		player.get_parent().get_parent().player_leave("starkandco")
		if twitch_node.parties.has("starkandco"):
			twitch_node.parties.erase("starkandco")
		twitch_node.players.erase("starkandco")
	else:
		twitch_node.players.erase("starkandco")

func _on_close_requested():
	visible = false

func _on_line_edit_say_text_submitted(new_text):
	twitch_node._custom_handle_command({"user": "starkandco"}, new_text)

