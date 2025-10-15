shader_type spatial;

render_mode blend_mix, depth_prepass_alpha, cull_back;

// ─────────────── TEXTURES ───────────────
uniform sampler2D albedo_texture : source_color;
uniform sampler2D mask_texture;

// ─────────────── RECOLOR ───────────────
uniform vec4 recolor : source_color = vec4(1.0, 0.0, 0.0, 1.0);

// ─────────────── MATERIAL PARAMETERS ───────────────
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float specular : hint_range(0.0, 1.0) = 0.5;

// ─────────────── ALPHA SCISSOR (manual) ───────────────
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    float mask = texture(mask_texture, UV).r;

    // Recolor the masked area
    vec3 final_rgb = mix(tex.rgb, recolor.rgb, mask);

    ALBEDO = final_rgb;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = specular;
    ALPHA = tex.a;

    // Manual alpha scissor (replaces ALPHA_SCISSOR)
    if (ALPHA < alpha_scissor_threshold) {
        discard;
    }
}
