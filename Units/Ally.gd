extends Unit

class_name Ally

func _ready():
	dialogue_tree = {
	"text": "Hello, traveler. Take this! Let me know if there's anything at all else we can do for you!!",
	"options": [
		{
			"text": "Thanks",
			"callback": "custom_end"
		}	]	}

func handle_response(arg):
	
	huh = {
	"text": "Are you feeling alright??",
	"options": [
		{
			"text": "Thanks",
			"callback": "custom_end"
		}	]	}
	
	match arg.to_upper():
		"THANKS":
			dialogue_UI.on_option_selected("custom_end")
		var _default:
			dialogue_UI.on_option_selected("show_huh")

func custom_end():
	get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/Inventory").share_item(Potion.new(), null)
	end_dialogue()
