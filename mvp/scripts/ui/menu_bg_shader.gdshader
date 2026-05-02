shader_type canvas_item;

// Gradient colors tuned to match the maquette (dark -> purple)
// Gradient stops calibrated to maquette (#0B0610 -> #2A0A2A -> #5F1A66)
uniform vec3 col0 = vec3(0.043137, 0.023529, 0.062745);
uniform vec3 col1 = vec3(0.164706, 0.039216, 0.164706);
uniform vec3 col2 = vec3(0.372549, 0.101961, 0.4);

// Blobs positioned and scaled for visual match
uniform vec2 blob1_center = vec2(0.78, 0.30);
uniform float blob1_scale = 0.44;
uniform float blob1_intensity = 0.60;

uniform vec2 blob2_center = vec2(0.50, 0.75);
uniform float blob2_scale = 0.28;
uniform float blob2_intensity = 0.42;

uniform vec3 blobcol1 = vec3(0.796078, 0.650980, 1.0); // soft lilac
uniform vec3 blobcol2 = vec3(0.796078, 0.650980, 1.0);

void fragment() {
    vec2 uv = UV;
    // rotate UV around center for 135deg gradient
    float angle = radians(135.0);
    mat2 rot = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
    float t = dot(rot * (uv - vec2(0.5)), vec2(1.0, 1.0)) + 0.5;
    vec3 base = mix(col0, col1, smoothstep(0.0, 0.5, t));
    base = mix(base, col2, smoothstep(0.5, 1.0, t));

    float d1 = length(uv - blob1_center) * blob1_scale;
    float blob1 = smoothstep(0.98, 0.0, d1);
    float d2 = length(uv - blob2_center) * blob2_scale;
    float blob2 = smoothstep(0.99, 0.0, d2);

    vec3 color = base + blobcol1 * blob1 * blob1_intensity + blobcol2 * blob2 * blob2_intensity;
    COLOR = vec4(color, 1.0);
}
