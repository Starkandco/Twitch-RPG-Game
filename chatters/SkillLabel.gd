extends Label

func update_label():
	var new_text = ""
	for player in get_parent().get_parent().get_parent().get_parent().get_child(1).get_node("Players").get_children():
		if player.potential_skills.size() == 0: continue
		if new_text == "":
			new_text += "Available skills:\n"
		new_text += player.user
		for skill in player.potential_skills:
			new_text += ": " + skill + " (" + player.potential_skills[skill] + ")"
		new_text += "\n"
	text = new_text
