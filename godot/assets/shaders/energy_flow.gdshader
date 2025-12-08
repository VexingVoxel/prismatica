shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 flow_color : source_color = vec4(0.0, 0.8, 1.0, 1.0); // Cyanish
uniform float speed = 2.0;
uniform float turbulence = 5.0;

void fragment() {
    vec2 uv = UV;
    
    // Scroll noise along X (length of the line)
    float noise_val = sin(uv.x * 20.0 - TIME * speed) * 0.5 + 0.5;
    
    // Add turbulence
    float turb = sin(uv.x * turbulence + TIME * speed * 2.0) * 0.2;
    
    // Combine
    float intensity = noise_val + turb;
    
    // Mix colors
    vec4 final_color = mix(base_color, flow_color, intensity);
    
    // Add edge glow (for Line2D UVs, Y is usually 0..1 across width)
    float edge = 1.0 - abs(uv.y - 0.5) * 2.0;
    edge = smoothstep(0.0, 0.2, edge); // Soften edges
    
    final_color.a *= edge;
    
    COLOR = final_color;
}
