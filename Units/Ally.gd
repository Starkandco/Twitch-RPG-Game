extends Unit

class_name Ally

var current_tree = 0

var dialogue_tree_2 = {
	"text": "Our village is known for its beautiful scenery and friendly people.",
	"options": [
		{
			"text": "Ok..",
			"callback": "show_dialogue_tree_3"
		}	]	}
var dialogue_tree_3 = {
	"text": "Feel free to explore and enjoy your stay!",
	"options": [
		{
			"text": "Thanks",
			"callback": "show_dialogue_tree_4"
		}	]	}
var dialogue_tree_4 = {
	"text": "Let me know if there's anything at all else we can do for you!!",
	"options": [
		{
			"text": "kthx bye",
			"callback": "end_dialogue"
		}	]	}

func _ready():
	dialogue_tree = {
	"text": "Hello, traveler! Welcome to our village.",
	"options": [
		{
			"text": "Continue",
			"callback": "show_dialogue_tree_2"
		}	]	}

func handle_response(arg):
	
	huh = {
	"text": "Are you feeling alright??",
	"options": [
		{
			"text": "Continue",
			"callback": "show_dialogue_tree_2"
		} if current_tree == 0 else
		{
			"text": "Ok..",
			"callback": "show_dialogue_tree_3"
		} if current_tree == 1 else
		{
			"text": "Thanks",
			"callback": "show_dialogue_tree_4"
		} if current_tree == 2 else
		{
			"text": "kthx bye",
			"callback": "end_dialogue"
		}	]	}
	
	match arg.to_upper():
		"CONTINUE":
			if current_tree == 0:
				dialogue_UI.on_option_selected("show_dialogue_tree_2")
			else: dialogue_UI.on_option_selected("show_huh")
		"OK..":
			if current_tree == 1:
				dialogue_UI.on_option_selected("show_dialogue_tree_3")
			else: dialogue_UI.on_option_selected("show_huh")
		"THANKS":
			if current_tree == 2:
				dialogue_UI.on_option_selected("show_dialogue_tree_4")
			else: dialogue_UI.on_option_selected("show_huh")
		"KTHX BYE":
			if current_tree == 3:
				dialogue_UI.on_option_selected("end_dialogue")
			else: dialogue_UI.on_option_selected("show_huh")
		var _default:
			dialogue_UI.on_option_selected("show_huh")

func show_dialogue_tree_2():
	current_tree += 1
	dialogue_UI.show_dialogue(self, dialogue_tree_2)

func show_dialogue_tree_3():
	current_tree += 1
	dialogue_UI.show_dialogue(self, dialogue_tree_3)

func show_dialogue_tree_4():
	current_tree += 1
	dialogue_UI.show_dialogue(self, dialogue_tree_4)

