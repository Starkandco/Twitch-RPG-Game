shader_type canvas_item;

uniform vec4 colour_from: source_color;
uniform vec4 colour_to: source_color;

void fragment() {
	if(distance(COLOR, colour_from) < 0.1){
		COLOR = colour_to;
	}
}
