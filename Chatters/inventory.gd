extends Control

func display_user(player):
	$MarginContainer/GridContainer/Potions/Label2.text = str(player.potions)
	$MarginContainer/GridContainer/Elixirs/Label2.text = str(player.elixirs)

func toggle_visibility():
	visible = !visible

func share_item(item, calling_user):
	match item.get_script():
		Potion:
			for player in get_parent().get_parent().get_parent().get_child(1).get_node("Players").get_children():
				if player.user != calling_user:
					player.potions += 1
		Elixir:
			for player in get_parent().get_parent().get_parent().get_child(1).get_node("Players").get_children():
				if player.user != calling_user:
					player.elixirs += 1
