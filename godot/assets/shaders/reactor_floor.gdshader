shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.08, 0.08, 0.1, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.0, 0.4, 0.4, 0.5); // Dim Cyan

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5);
    float dist = distance(uv, center);
    
    // 1. Radial Vents
    // atan gives angle. sin(angle * frequency) gives stripes.
    float angle = atan(uv.y - 0.5, uv.x - 0.5);
    float vents = step(0.5, sin(angle * 20.0)); // 20 spokes
    
    // Restrict vents to a ring
    float ring_mask = smoothstep(0.2, 0.21, dist) * (1.0 - smoothstep(0.45, 0.46, dist));
    
    // 2. Central Plate
    float plate_mask = 1.0 - smoothstep(0.18, 0.19, dist);
    
    // 3. Outer Hex/Circuit Border
    // Simple box border for now
    float border_mask = step(0.48, max(abs(uv.x - 0.5), abs(uv.y - 0.5)));
    
    // Combine
    vec4 color = base_color;
    
    // Add Vents
    color = mix(color, highlight_color, vents * ring_mask * 0.3);
    
    // Add Plate Glow
    color = mix(color, highlight_color, plate_mask * 0.5);
    
    // Add Border
    color = mix(color, highlight_color, border_mask);
    
    COLOR = color;
}
