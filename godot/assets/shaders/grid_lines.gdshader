shader_type canvas_item;
render_mode blend_add;

uniform vec4 line_color : source_color = vec4(0.5, 0.5, 0.5, 1.0); 
uniform float grid_size = 64.0; 
uniform float line_thickness = 1.0;

// Lighting
const int MAX_LIGHTS = 128;
uniform vec2 light_sources[MAX_LIGHTS];
uniform int light_count = 0;
uniform float light_radius = 250.0;
uniform float light_falloff = 50.0;

varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec2 pos = world_pos;
    
    // 1. Grid Line Logic
    vec2 cell_pos = mod(pos + vec2(grid_size * 0.5), grid_size);
    float dist_x = min(cell_pos.x, grid_size - cell_pos.x);
    float dist_y = min(cell_pos.y, grid_size - cell_pos.y);
    float dist = min(dist_x, dist_y);
    float grid_alpha = 1.0 - smoothstep(line_thickness - 0.5, line_thickness + 1.0, dist);
    
    // 2. Lighting Logic
    float light_mask = 0.0;
    
    // Optimization: Check if we are totally far from origin? 
    // No, iterating 100 times is fast.
    
    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (i >= light_count) break;
        float d = distance(pos, light_sources[i]);
        // Smooth falloff: 1.0 at center, 0.0 at radius
        // smoothstep(edge0, edge1, x) -> 0 at edge0, 1 at edge1
        // We want 1 near source (d < radius - falloff)
        // 0 far from source (d > radius)
        float l = 1.0 - smoothstep(light_radius - light_falloff, light_radius, d);
        light_mask += l;
    }
    
    // Clamp mask
    light_mask = clamp(light_mask, 0.0, 1.0);
    
    // Combine
    vec4 final_color = line_color;
    final_color.a *= grid_alpha * light_mask;
    
    COLOR = final_color;
}