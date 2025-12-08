shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.01, 0.01, 0.01, 1.0); 
uniform vec4 cloud_color : source_color = vec4(0.04, 0.08, 0.12, 0.2); 
uniform float speed : hint_range(0.0, 1.0) = 0.01; 
uniform float tile_factor = 20.0; // How many times noise repeats across the rect

// Better Gold Noise (Avoiding sin() artifacts)
// PHI = 1.61803398874989484820459
float random(vec2 xy) {
    return fract(tan(distance(xy * 1.61803398, xy) * xy.x) * xy.y); 
}
// Standard Hash
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 2D Noise
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// FBM
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.5)));
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(st);
        st = rot * st * 2.0 + vec2(100.0); // Add shift to break symmetries
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    // Tile the UVs significantly to avoid stretching
    vec2 uv = UV * tile_factor; 
    
    // Animate
    float time = TIME * speed;
    
    // Domain Warping
    vec2 q = vec2(0.0);
    q.x = fbm(uv + time * 0.2);
    q.y = fbm(uv + vec2(5.2, 1.3) + time * 0.3);
    
    vec2 r = vec2(0.0);
    r.x = fbm(uv + 4.0 * q + vec2(1.7, 9.2) + 0.15 * time);
    r.y = fbm(uv + 4.0 * q + vec2(8.3, 2.8) + 0.126 * time);
    
    float f = fbm(uv + 4.0 * r);
    
    // Contrast Curve (Subtle)
    float intensity = pow(f, 3.5); 
    
    COLOR = mix(bg_color, cloud_color, clamp(intensity * 1.5, 0.0, 1.0));
}