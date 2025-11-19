shader_type canvas_item;

uniform float amplitude : hint_range(0.0, 10.0) = 2.0;
uniform float speed : hint_range(0.0, 10.0) = 1.0;
uniform float edge_size : hint_range(0.0, 1.0) = 0.2;
uniform float frequency1 : hint_range(0.0, 20.0) = 6.0;
uniform float frequency2 : hint_range(0.0, 20.0) = 12.0;

void fragment() {
    vec2 uv = UV;

    // Distance from center
    float dist = length(uv - vec2(0.5));
    float edge_mask = smoothstep(1.0 - edge_size, 1.0, dist);

    float t = TIME * speed;

    // Two layered waves
    float wave1 = sin(uv.y * frequency1 + t);
    float wave2 = sin(uv.x * frequency2 + t * 1.29);
    float wave3 = sin((uv.x + uv.y) * (frequency1 * 0.5) + t * 0.77);

    float wiggle = (wave1 + wave2 * 0.6 + wave3 * 0.4) * (amplitude * 0.01);

    // Apply radial distortion only on edges
    uv += normalize(uv - vec2(0.5)) * wiggle * edge_mask;

    // Clamp UV to keep texture visible
    uv = clamp(uv, vec2(0.0), vec2(1.0));

    COLOR = texture(TEXTURE, uv) * COLOR;
}
