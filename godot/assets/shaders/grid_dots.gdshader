shader_type canvas_item;

uniform vec4 dot_color : source_color = vec4(0.0, 0.9, 1.0, 0.5); // Cyan
uniform float grid_size = 64.0; 
uniform float dot_radius = 2.0;
uniform float pulse_speed = 1.0;

varying vec2 world_pos;

void vertex() {
    // Calculate world position
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec2 pos = world_pos;
    
    // Grid Logic
    vec2 cell_pos = mod(pos, grid_size);
    // Center of cell is grid_size/2
    vec2 center_dist = cell_pos - vec2(grid_size * 0.5);
    float dist = length(center_dist);
    
    // Draw Dot
    float alpha = 1.0 - smoothstep(dot_radius - 1.0, dot_radius + 1.0, dist);
    
    // Pulse Effect
    vec2 cell_index = floor(pos / grid_size);
    float random_offset = fract(sin(dot(cell_index, vec2(12.9898, 78.233))) * 43758.5453);
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed + random_offset * 6.28);
    
    vec4 final_color = dot_color;
    final_color.a *= alpha * pulse;
    
    COLOR = final_color;
}