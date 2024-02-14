extends Panel

class_name BasePanel

@export var has_option_panel_child: bool = false

func _ready():
	if material.get_shader_parameter("top_left") == PanelColourManager.menu_colours["top_left"]: return
	material.set_shader_parameter("top_left", PanelColourManager.menu_colours["top_left"])
	material.set_shader_parameter("top_right", PanelColourManager.menu_colours["top_right"])
	material.set_shader_parameter("bottom_left", PanelColourManager.menu_colours["bottom_left"])
	material.set_shader_parameter("bottom_right", PanelColourManager.menu_colours["bottom_right"])

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
	await get_tree().process_frame
	material.set_shader_parameter("top_left", Color(colour_a))
	material.set_shader_parameter("top_right", Color(colour_b))
	material.set_shader_parameter("bottom_right", Color(colour_c))
	material.set_shader_parameter("bottom_left", Color(colour_d))
	if !has_option_panel_child: return
	get_node("OptionPanel").change_colours(colour_a, colour_b, colour_c, colour_d)
