extends StaticBody2D

class_name Unit

@onready var dialogue_UI = get_parent().get_parent().get_parent().get_node("GameUI/DialoguePanel")
var dialogue_tree = {}
var huh = {}

signal interaction_finished

func interact():
	dialogue_UI.show_dialogue(self, dialogue_tree)

func call_dialogue_callback(callback_name):
	var new_callable = Callable(self, callback_name)
	if new_callable.is_valid():
		new_callable.call()
	else:
		show_huh()

func show_huh():
	dialogue_UI.show_dialogue(self, huh)

func end_dialogue():
	interaction_finished.emit()
