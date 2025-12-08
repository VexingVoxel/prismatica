shader_type canvas_item;

uniform vec4 core_color : source_color = vec4(4.0, 2.0, 0.5, 1.0); // HDR Amber
uniform vec4 edge_color : source_color = vec4(4.0, 1.0, 0.0, 1.0); // Red-Orange
uniform float turbulence_speed = 1.0;

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

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv) * 2.0; // 0..1 edge
    
    // Noise Animation
    float time = TIME * turbulence_speed;
    float n = noise(uv * 10.0 + time);
    float n2 = noise(uv * 20.0 - time * 1.5);
    
    // Combine Noise
    float turb = (n + n2) * 0.5;
    
    // Edge Glow / Softness
    // 1.0 at center, 0.0 at edge
    float glow = 1.0 - smoothstep(0.0, 1.0, dist);
    
    // Turbulent Edge
    // Distort the distance field with noise
    float distorted_dist = dist + (turb * 0.1);
    float orb_mask = 1.0 - smoothstep(0.8, 0.9, distorted_dist);
    
    // Color Gradient
    // Center is Core Color, Edge is Edge Color
    vec4 final_color = mix(edge_color, core_color, glow + (turb * 0.2));
    
    // Apply Mask
    final_color.a *= orb_mask;
    
    COLOR = final_color;
}
