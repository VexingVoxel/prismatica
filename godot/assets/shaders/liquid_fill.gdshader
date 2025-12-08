shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(0.0, 0.8, 0.8, 1.0);
uniform vec4 bg_color : source_color = vec4(0.0, 0.2, 0.2, 0.5);
uniform float fill_level : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Simple vertical fill
	// Invert fill_level so 1.0 is full (top) and 0.0 is empty (bottom)
	// UV.y goes 0 (top) to 1 (bottom)
	float threshold = 1.0 - fill_level;
	
	if (UV.y < threshold) {
		// Empty part
		COLOR = bg_color;
	} else {
		// Filled part
		COLOR = fill_color;
	}
}
