shader_type spatial;

//Color and Texture type Variables
uniform vec4 water_color: source_color;
uniform vec4 fresnel_color: source_color;
uniform vec4 depth_color: source_color;
uniform float roughness = 0.05;

//Normalmap Variables
uniform float normalmap_a_str: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float normalmap_b_str: hint_range(0.0, 1.0, 0.01) = 0.25;
uniform sampler2D normalmap_a: hint_normal;
uniform sampler2D normalmap_b: hint_normal;
uniform vec2 movement_direction = vec2(0.2, 0.1);
uniform float movement_strength = 0.12;

//Wave Variabels
uniform sampler2D wave;
uniform float time_scale: hint_range(0.0, 0.2, 0.005) = 0.025; //Speed of waves across time
uniform float noise_scale = 10.0;
uniform float height_scale = 0.05;

//Fresnel Variables
uniform float fresnel_scale = 0.05;
uniform float near = 1.0;
uniform float far = 100.0;

//UV Variables
uniform float uv_scale = 1.0;

//Depth Variables
uniform float depth_distance: hint_range(0.0, 20.0, 0.1) = 2.0;
uniform float beers_law: hint_range(0.0, 20.0, 0.1) = 1.0; //Attenuation of Light
uniform float water_transparency: hint_range(0.0, 1.0, 0.01) = 0.1;

//Refraction Variables
uniform float refraction_strength: hint_range(0.0, 8.0, 0.01) = 0.05;

//Restore old version Variables
uniform sampler2D depth_texture: hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;


//Varying Variables
varying float height;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_pos.xz / noise_scale + TIME * time_scale).r;
	VERTEX.y += height * height_scale;
}

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

float edge(float depth){
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}

void fragment() {
	//Getting Edge Depth calc
	float z_depth = edge(texture(depth_texture, SCREEN_UV).x);
	float z_pos = edge(FRAGCOORD.z);
	float z_dif = z_depth - z_pos;
	
	//Time calculations for direction (normal map) movement
	vec2 uv = UV * uv_scale;
	vec2 uv_movement = movement_direction * TIME * movement_strength;
	
	//Blend normal maps into one
	vec3 normalmap = texture(normalmap_a, UV + uv_movement).rgb * normalmap_a_str;
	normalmap += texture(normalmap_b, UV - uv_movement).rgb * normalmap_b_str;
	
	//Create refraction with normalmap
	vec3 ref_normalmap = normalmap * 2.0 - (normalmap_a_str + normalmap_b_str);
	vec3 ref_normal = mix(NORMAL, TANGENT * ref_normalmap + BINORMAL * ref_normalmap + NORMAL * ref_normalmap, 1.0);
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction_strength;
	
	//------------------Everything above needs to be above the section "Get Depth and Screen Textures" to work----------------
	
	// Get Depth and Screen Textures
	float depth_clean = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	float depth = textureLod(depth_texture, ref_ofs, 0.0).r;
	vec3 screen = textureLod(screen_texture, ref_ofs, 0.0).rgb;
	
	//Get Depth in World Position (Y)
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec3 ndc_clean = vec3(SCREEN_UV * 2.0 - 1.0, depth_clean); //Undistorted UV
	
	//Get Depth in View Matrix
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z + VERTEX.z; //Checks if object is in front of water plane
	
	vec4 world;
	
	//If object is in front, use undistorted UVs
	if (linear_depth < 0.00001) {
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc_clean, 1.0);
	}
	else {
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	}
	
	
	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	
	//Set Depth Blend and adjust with Beer's Law
	float depth_blend = clamp((vertex_y - depth_texture_y) / depth_distance, 0.0, 1.0);
	depth_blend = exp(-depth_blend * beers_law);
	
	//Calculate Fresnel
	float fresnel = fresnel(4.0, NORMAL, VIEW);
	
	//Set Depth Color mix from depth blend and get final color mix using screen texture
	vec4 surface_color = mix(water_color, fresnel_color, fresnel); //Interpolate albedo values by fresnel
	vec4 blended_depth_color = mix(depth_color, surface_color, depth_blend);
	vec3 adjusted_depth_color = mix(fresnel_color, blended_depth_color, step(fresnel_scale, z_dif)).rgb;
	
	//If object is in front, use undistorted UVs
	vec3 refraction_texture;
	if (linear_depth < 0.00001) {
		refraction_texture = textureLod(screen_texture, SCREEN_UV, ROUGHNESS * 2.0).rgb;
	}
	else {
		refraction_texture = textureLod(screen_texture, ref_ofs, ROUGHNESS * 2.0).rgb;
	}
	
	vec3 final_color = mix(adjusted_depth_color, refraction_texture, water_transparency * depth_blend);
	
	ALBEDO = final_color;//mix(final_color, screen, depth_blend * (0.2 - fresnel));//surface_color.rgb + (0.2 * fresnel);//mix(surface_color, color, 0.75);
	ROUGHNESS = roughness * (1.0 - fresnel);
	NORMAL_MAP = normalmap;
}