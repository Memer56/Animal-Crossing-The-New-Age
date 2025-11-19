shader_type canvas_item;

uniform float transition_progress : hint_range(0.0, 1.0) = 0.0;
uniform bool shrink = true;              // true = circle closes, false = opens
uniform float edge : hint_range(0.0, 0.2) = 0.02; // edge softness

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 center = vec2(0.5, 0.5);

    // --- Fix stretching by accounting for aspect ratio ---
    float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    vec2 aspect_uv = vec2((uv.x - center.x) / aspect, uv.y - center.y);

    float dist = length(aspect_uv);

    // Find the farthest distance (so full screen can be covered)
    float max_radius = length(vec2(0.5 / aspect, 0.5));
    float min_radius = 0.0;

    // Compute radius based on direction
    float radius = shrink
        ? mix(max_radius, min_radius, transition_progress)
        : mix(min_radius, max_radius, transition_progress);

    // smoothstep fade between transparent and opaque
    float mask = smoothstep(radius, radius + edge, dist);

    // Inside circle transparent, outside opaque
    COLOR = vec4(0.0, 0.0, 0.0, mask);
}
