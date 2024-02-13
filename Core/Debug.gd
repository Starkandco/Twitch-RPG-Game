extends Window

@onready var grid = $"../SubViewportContainer/OverallGameSubViewport/MarginContainer/ChatterGridContainer"
func _on_button_pressed():
	grid.party_start()
	
func _on_button_2_pressed():
	for child in grid.get_children():
		child.get_node("ChatterGameSubViewport/GameScene").player_join("Test" + str(randi() % 100000))

func _on_line_edit_text_submitted(new_text):
	var new_value = new_text.to_int()
	if new_value:
		grid.party_end(new_value - 1)

func _on_close_requested():
	visible = false

func _on_line_edit_say_text_submitted(new_text):
	var players = get_tree().get_nodes_in_group("Player")
	for player in players:
		player.say(new_text)

func _on_line_edit_2_text_submitted(new_text):
	var players = get_tree().get_nodes_in_group("Player")
	for player in players:
		var new_callable = Callable(player, new_text)
		if new_callable.is_valid():
			new_callable.call()
