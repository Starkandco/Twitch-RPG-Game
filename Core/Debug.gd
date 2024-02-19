extends Window

@onready var twitch_node = $"../BackgroundRect"
var user = "starkandco"

func _process(_delta):
	if Input.is_action_just_pressed("debug"):
		visible = !visible

func _on_line_edit_text_submitted(new_text):
	user = new_text

func _on_button_pressed():
	twitch_node._join({"sender_data":{"user": user}})
	
func _on_button_2_pressed():
	twitch_node._custom_handle_command({"user": user}, "start party")

func _on_button_3_pressed():
	twitch_node._custom_handle_command({"user": user}, "start adventure")

func _on_button_4_pressed():
	twitch_node._leave({"sender_data":{"user": user}})

func _on_close_requested():
	visible = false

func _on_line_edit_say_text_submitted(new_text):
	twitch_node._custom_handle_command({"user": user}, new_text)
