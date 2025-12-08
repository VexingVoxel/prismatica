shader_type canvas_item;

uniform vec4 ring_color : source_color = vec4(0.0, 2.0, 2.0, 1.0); // HDR Cyan
uniform int segments = 12;
uniform float gap_size : hint_range(0.0, 1.0) = 0.2;
uniform float speed = 0.5;

void fragment() {
    vec2 uv = UV;
    
    // Assume Line2D with UV.x along length, UV.y across width
    // UV.x goes 0..1 (or more if tiled).
    // We want segments along the length.
    
    float segment_pos = fract(uv.x * float(segments) + TIME * speed);
    
    // Gap Logic
    // If segment_pos < gap_size, discard or alpha 0
    float alpha = step(gap_size, segment_pos);
    
    // Edge Fade (Width)
    float width_alpha = 1.0 - abs(uv.y - 0.5) * 2.0;
    width_alpha = smoothstep(0.0, 0.2, width_alpha);
    
    vec4 final_color = ring_color;
    final_color.a *= alpha * width_alpha;
    
    COLOR = final_color;
}
