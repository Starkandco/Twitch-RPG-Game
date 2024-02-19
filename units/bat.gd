extends Enemy

class_name Bat


func _ready():
	super()
	dialogue_tree = {
	"text": "SCREEEEEECH",
	"options": [
		{
			"text": "Ow",
			"callback": "start_fight"
		}	]	}

func handle_response(arg):
	if health > 0:
		dialogue_UI.on_option_selected("start_fight")
	else:
		huh = {
		"text": ("You can \"continue\" on now"),
		"options": [
			{
				"text": "Continue",
				"callback": "end_interaction"
			} 	]	}
		match arg.to_upper():
			"CONTINUE":
				dialogue_UI.on_option_selected("end_interaction")
			var _default:
				count += 1
				dialogue_UI.on_option_selected("show_huh")
