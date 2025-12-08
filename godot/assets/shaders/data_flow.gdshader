shader_type canvas_item;

uniform vec4 flow_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform float line_width : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Simple scrolling gradient/pulse along the UV.x (length of the line)
	float pulse = sin(UV.x * 10.0 - TIME * speed);
	float alpha = smoothstep(0.0, 1.0, pulse);
	
	COLOR = flow_color;
	COLOR.a *= alpha;
}
