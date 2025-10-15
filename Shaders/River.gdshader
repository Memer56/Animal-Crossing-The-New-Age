shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec3 shallow_color : source_color = vec3(0.05, 0.7, 1.0);
uniform vec3 deep_color    : source_color = vec3(0.0, 0.45, 0.9);
uniform vec3 foam_color    : source_color = vec3(1.0, 1.0, 1.0);

uniform float foam_distance  : hint_range(0.0, 0.05) = 0.01;
uniform float foam_strength  : hint_range(0.0, 3.0) = 1.5;
uniform float flow_speed     : hint_range(-3.0, 3.0) = 0.8;
uniform float streak_speed   : hint_range(-3.0, 3.0) = 0.6;
uniform float streak_density : hint_range(0.5, 10.0) = 4.0;
uniform float wave_amplitude : hint_range(0.0, 0.5) = 0.08;
uniform float wave_frequency : hint_range(1.0, 10.0) = 4.0;
uniform float wave_speed     : hint_range(-3.0, 3.0) = 1.0;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;

float rand(vec2 n) { return fract(sin(dot(n, vec2(12.9898,78.233))) * 43758.5453); }
float noise(vec2 p){
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = rand(i);
	float b = rand(i+vec2(1.,0.));
	float c = rand(i+vec2(0.,1.));
	float d = rand(i+vec2(1.,1.));
	vec2 u = f*f*(3.-2.*f);
	return mix(a,b,u.x)+(c-a)*u.y*(1.-u.x)+(d-b)*u.x*u.y;
}

void vertex() {
	VERTEX.y += sin(UV.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
}

// helper to convert depth to linear 0–1 distance
float linearize_depth(float depth) {
	float z_near = 0.01; // adjust to your camera near
	float z_far = 500.0; // adjust to your camera far
	return (2.0 * z_near) / (z_far + z_near - depth * (z_far - z_near));
}

void fragment() {
	vec2 uv = UV;
	uv.y += TIME * flow_speed;

	// color gradient (depth-based within plane)
	float depth_factor = smoothstep(0.0, 1.0, abs(uv.x - 0.5) * 2.0);
	vec3 base = mix(shallow_color, deep_color, depth_factor);

	// screen-space foam (using scene depth)
	vec2 screen_uv = SCREEN_UV;
	float scene_depth = texture(DEPTH_TEXTURE, screen_uv).r;

	// our own fragment depth (linear)
	float water_depth = linearize_depth(FRAGCOORD.z);

	// compare scene and water depth
	float depth_diff = abs(scene_depth - water_depth);
	float foam_mask = smoothstep(foam_distance, 0.0, depth_diff);
	foam_mask = clamp(foam_mask, 0.0, 1.0);

	// flowing streaks
	vec2 n_uv = vec2(uv.x * streak_density, uv.y * 2.0 + TIME * streak_speed);
	float n = noise(n_uv);
	float streaks = smoothstep(0.7, 1.0, n);

	vec3 color = base + streaks * 0.15;
	color = mix(color, foam_color, foam_mask * foam_strength);

	ALBEDO = color;
}
