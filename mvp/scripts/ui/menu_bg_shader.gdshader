shader_type canvas_item;

// Royaume déchu: obsidian, wine-red shadows, restrained violet magic.
uniform vec3 col0 = vec3(0.027, 0.010, 0.035);
uniform vec3 col1 = vec3(0.090, 0.025, 0.075);
uniform vec3 col2 = vec3(0.170, 0.055, 0.190);

uniform vec2 blob1_center = vec2(0.80, 0.26);
uniform float blob1_scale = 0.78;
uniform float blob1_intensity = 0.16;
uniform vec2 blob2_center = vec2(0.18, 0.82);
uniform float blob2_scale = 0.72;
uniform float blob2_intensity = 0.12;

uniform vec3 blobcol1 = vec3(0.52, 0.18, 0.58);
uniform vec3 blobcol2 = vec3(0.55, 0.12, 0.20);

void fragment() {
    vec2 uv = UV;
    float t = clamp((uv.x * 0.38) + (uv.y * 0.62), 0.0, 1.0);
    vec3 base = mix(col0, col1, smoothstep(0.0, 0.56, t));
    base = mix(base, col2, smoothstep(0.56, 1.0, t));

    float d1 = distance(uv, blob1_center);
    float d2 = distance(uv, blob2_center);
    float blob1 = 1.0 - smoothstep(0.0, blob1_scale, d1);
    float blob2 = 1.0 - smoothstep(0.0, blob2_scale, d2);

    vec3 color = base + blobcol1 * blob1 * blob1_intensity + blobcol2 * blob2 * blob2_intensity;
    float vignette = smoothstep(0.92, 0.24, distance(uv, vec2(0.5)));
    color *= mix(0.78, 1.0, vignette);
    COLOR = vec4(color, 1.0);
}
