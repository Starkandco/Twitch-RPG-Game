extends Control

var label_container = []

@onready var grid = $MarginContainer/GridContainer
@onready var potions = $MarginContainer/GridContainer/Potions
@onready var chatter_grid = get_parent().get_parent().get_parent().get_parent().get_parent()

func _process(_delta):
	check_and_update_labels()

func check_and_update_labels():
	if chatter_grid.columns == 3 and potions.has_node("Label"):
		for child in grid.get_children():
			label_container.append(child.get_node("Label"))
			child.remove_child(child.get_node("Label"))
			while child.has_node("Label"):
				await get_tree().process_frame
	elif chatter_grid.columns < 3 and !potions.has_node("Label"):
		for child in grid.get_children():
			child.add_child(label_container.pop_front())
			while !child.has_node("Label"):
				await get_tree().process_frame

func load_potions(number):
	potions.get_node("Label2").text = str(number)

func gain_potion():
	potions.get_node("Label2").text = str(potions.get_node("Label2").text.to_int() + 1)

func lose_potion():
	potions.get_node("Label2").text = str(potions.get_node("Label2").text.to_int() + 1)
