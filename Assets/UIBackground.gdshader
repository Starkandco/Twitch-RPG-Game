shader_type canvas_item;

uniform vec4 top_left : source_color;
uniform vec4 top_right : source_color;
uniform vec4 bottom_left : source_color;
uniform vec4 bottom_right : source_color;

uniform float border_outer_hori_threshold;
uniform float border_outer_vert_threshold;
uniform float border_middle_hori_threshold;
uniform float border_middle_vert_threshold;
uniform float border_inner_hori_threshold;
uniform float border_inner_vert_threshold;

void fragment() {
    // Figure out our relation to the border
    float left_border = UV.x;
    float right_border = 1.0 - UV.x;
    float bottom_border = UV.y;
    float top_border = 1.0 - UV.y;
    
    // Let's check if the current position is on an outer, middle or inner border
    bool is_outer_left_border = left_border < border_outer_hori_threshold;
    bool is_outer_right_border = right_border < border_outer_hori_threshold;
    bool is_outer_bottom_border = bottom_border < border_outer_vert_threshold;
    bool is_outer_top_border = top_border < border_outer_vert_threshold;

    bool is_middle_left_border = left_border < border_middle_hori_threshold;
    bool is_middle_right_border = right_border < border_middle_hori_threshold;
    bool is_middle_bottom_border = bottom_border < border_middle_vert_threshold;
    bool is_middle_top_border = top_border < border_middle_vert_threshold;

    bool is_inner_left_border = left_border < border_inner_hori_threshold;
    bool is_inner_right_border = right_border < border_inner_hori_threshold;
    bool is_inner_bottom_border = bottom_border < border_inner_vert_threshold;
    bool is_inner_top_border = top_border < border_inner_vert_threshold;
    
    // Default colours
    vec4 border_border_colour = vec4(0.0, 0.0, 0.0, 1.0); // Black
    vec4 middle_border_colour = vec4(1.0, 1.0, 1.0, 1.0); // White
    vec4 colour;
    
    // Check for borders
    if (is_outer_left_border || is_outer_right_border || is_outer_bottom_border || is_outer_top_border) {
        // Fill in outer borders
        colour = border_border_colour;
    } else if (is_middle_left_border || is_middle_right_border || is_middle_bottom_border || is_middle_top_border) {
        // Fill in middle borders
        colour = middle_border_colour;
    } else if (is_inner_left_border || is_inner_right_border || is_inner_bottom_border || is_inner_top_border) {
        // Fill in inner borders
        colour = border_border_colour;
    } else {
        // Linear gradient blending
        vec4 top = mix(top_left, top_right, UV.x);
        vec4 bottom = mix(bottom_left, bottom_right, UV.x);
        colour = mix(top, bottom, UV.y);
    }
    COLOR = colour;
}