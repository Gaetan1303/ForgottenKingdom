shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.025, 0.018, 0.045, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.075, 0.028, 0.095, 1.0);
uniform vec4 violet_glow : source_color = vec4(0.43, 0.18, 0.56, 1.0);
uniform vec4 crimson_glow : source_color = vec4(0.52, 0.08, 0.16, 1.0);
uniform float animation_speed = 0.035;
uniform float glow_strength = 0.18;
uniform float vignette_strength = 0.52;

float soft_circle(vec2 uv, vec2 center, float radius, float feather) {
    float d = distance(uv, center);
    return 1.0 - smoothstep(radius - feather, radius, d);
}

void fragment() {
    vec2 uv = UV;
    vec3 base = mix(color_top.rgb, color_bottom.rgb, smoothstep(0.0, 1.0, uv.y));

    float t = TIME * animation_speed;
    vec2 violet_center = vec2(0.18 + sin(t * 0.9) * 0.035, 0.23 + cos(t * 0.7) * 0.025);
    vec2 crimson_center = vec2(0.83 + cos(t * 0.8) * 0.03, 0.72 + sin(t * 0.6) * 0.025);

    float vg = soft_circle(uv, violet_center, 0.54, 0.30);
    float rg = soft_circle(uv, crimson_center, 0.48, 0.28);
    base += violet_glow.rgb * vg * glow_strength;
    base += crimson_glow.rgb * rg * glow_strength * 0.75;

    float wave_a = sin((uv.x * 6.0 + uv.y * 2.0 + t * 1.4) * 3.14159265) * 0.5 + 0.5;
    float wave_b = sin((uv.y * 8.0 - uv.x * 1.5 - t) * 3.14159265) * 0.5 + 0.5;
    float wisps = pow(wave_a * wave_b, 4.0) * 0.022;
    base += vec3(0.28, 0.12, 0.36) * wisps;

    vec2 centered = uv - vec2(0.5);
    float vignette = smoothstep(0.25, 0.78, length(centered));
    base *= 1.0 - vignette * vignette_strength;

    float edge = smoothstep(0.0, 0.008, uv.x) * smoothstep(0.0, 0.008, uv.y)
        * smoothstep(0.0, 0.008, 1.0 - uv.x) * smoothstep(0.0, 0.008, 1.0 - uv.y);

    COLOR = vec4(base * edge, 1.0);
}
