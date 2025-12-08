shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 fill_color : source_color = vec4(0.0, 1.0, 1.0, 0.5);
uniform float outline_width : hint_range(0.0, 20.0) = 3.0;
uniform float fill_alpha : hint_range(0.0, 1.0) = 0.0;
uniform vec2 size = vec2(64.0, 64.0);

void fragment() {
    vec2 uv = UV;
    vec2 width_uv = outline_width / size;
    vec2 d = abs(uv - 0.5);
    
    float softness = 0.01;
    
    // Check Outline
    float alpha_x = smoothstep(0.5 - width_uv.x - softness, 0.5 - width_uv.x + softness, d.x);
    float alpha_y = smoothstep(0.5 - width_uv.y - softness, 0.5 - width_uv.y + softness, d.y);
    float is_outline = max(alpha_x, alpha_y);
    
    // Mix Color
    vec4 final_color = mix(fill_color, outline_color, is_outline);
    
    // Mix Alpha
    float alpha = mix(fill_alpha, outline_color.a, is_outline);
    final_color.a *= alpha;
    
    COLOR = final_color;
}
