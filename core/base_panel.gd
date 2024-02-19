extends Panel

class_name BasePanel


var bottom_right = PanelColourManager.menu_colours["bottom_right"]
var bottom_left = PanelColourManager.menu_colours["bottom_left"]
var top_right = PanelColourManager.menu_colours["top_right"]
var top_left = PanelColourManager.menu_colours["top_left"]

func _ready():
	change_colours(top_left, top_right, bottom_right, bottom_left)
	var border_size_pixels = 2
	
	var border_size_hori = border_size_pixels / size.x
	var border_size_vert = border_size_pixels / size.y
	
	material.set_shader_parameter("border_outer_hori_threshold", border_size_hori)
	material.set_shader_parameter("border_outer_vert_threshold", border_size_vert)
	material.set_shader_parameter("border_middle_hori_threshold", border_size_hori * 3)
	material.set_shader_parameter("border_middle_vert_threshold", border_size_vert * 3)
	material.set_shader_parameter("border_inner_hori_threshold", border_size_hori * 3.5)
	material.set_shader_parameter("border_inner_vert_threshold", border_size_vert * 3.5)

func _on_resized():
	change_colours(top_left, top_right, bottom_right, bottom_left)
	var border_size_pixels = 2
	var border_size_hori = border_size_pixels / size.x
	var border_size_vert = border_size_pixels / size.y
	
	if material.get_shader_parameter("border_outer_hori_threshold") == border_size_hori: return
	material.set_shader_parameter("border_outer_hori_threshold", border_size_hori)
	material.set_shader_parameter("border_outer_vert_threshold", border_size_vert)
	material.set_shader_parameter("border_middle_hori_threshold", border_size_hori * 3)
	material.set_shader_parameter("border_middle_vert_threshold", border_size_vert * 3)
	material.set_shader_parameter("border_inner_hori_threshold", border_size_hori * 3.5)
	material.set_shader_parameter("border_inner_vert_threshold", border_size_vert * 3.5)

func change_colours(colour_a, colour_b, colour_c, colour_d):
	top_left = colour_a
	top_right = colour_b
	bottom_right = colour_c
	bottom_left = colour_d
	await get_tree().process_frame
	material.set_shader_parameter("top_left", Color(top_left))
	material.set_shader_parameter("top_right", Color(top_right))
	material.set_shader_parameter("bottom_right", Color(bottom_right))
	material.set_shader_parameter("bottom_left", Color(bottom_left))
