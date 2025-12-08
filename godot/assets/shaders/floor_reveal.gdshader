shader_type canvas_item;

uniform vec4 floor_color : source_color = vec4(0.15, 0.15, 0.18, 1.0); 
uniform float grid_size = 64.0;

// Lighting
const int MAX_LIGHTS = 64;
uniform vec2 light_sources[MAX_LIGHTS];
uniform int light_count = 0;
uniform float light_radius = 250.0;
uniform float light_falloff = 50.0;

// Simple Hash
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 2D Noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float res = mix(mix(hash(i + vec2(0, 0)), hash(i + vec2(1, 0)), f.x),
                    mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
    return res;
}

// FBM
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 3; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    // Manual World Pos calculation for ColorRect spanning -50000 to 50000
    // UV is 0..1
    vec2 world_pos = (UV * 100000.0) - 50000.0;

    // 1. Calculate Light Mask
    float light_mask = 0.0;
    float max_intensity = 0.0;
    
    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (i >= light_count) break;
        float d = distance(world_pos, light_sources[i]);
        float l = 1.0 - smoothstep(light_radius - light_falloff, light_radius, d);
        light_mask += l;
        // Track intensity for 'hot spots' (center of lights)
        float intensity = 1.0 - smoothstep(0.0, light_radius, d);
        max_intensity = max(max_intensity, intensity);
    }
    light_mask = clamp(light_mask, 0.0, 1.0);
    
    // 2. Generate Texture (High Contrast Brushed Carbon)
    vec2 uv = world_pos * 0.02; // Larger noise pattern
    vec2 brushed_uv = vec2(uv.x + uv.y, uv.x - uv.y) * vec2(1.0, 8.0);
    float texture_val = fbm(brushed_uv);
    
    // 3. Base Material
    // High contrast mix: Dark Pits vs Shinier Ridges
    vec4 base = mix(floor_color * 0.5, floor_color * 1.8, texture_val);
    
    // 4. Lighting Simulation
    // Brighter lighting curve
    vec4 lit_color = base * (0.8 + 0.4 * max_intensity); 
    
    // 5. Reveal
    // Force solid alpha where mask is 1.0
    lit_color.a = light_mask;
    
    COLOR = lit_color;
}
