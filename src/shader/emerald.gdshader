shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec4  deep_color: source_color = vec4(0.01, 0.28, 0.08, 1.0);
uniform vec4  glow_color: source_color = vec4(0.10, 0.72, 0.22, 1.0);
uniform vec4  tint_color: source_color = vec4(0.05, 0.55, 0.35, 1.0);
uniform vec4  fresnel_color: source_color = vec4(0.90, 1.00, 0.94, 1.0);

uniform float glow_power: hint_range(0.2, 5.0, 0.05) = 1.4;
uniform float refraction_str: hint_range(0.0, 1.0, 0.01) = 0.25;
uniform float refraction_bend: hint_range(0.0, 0.2, 0.005) = 0.06;
uniform float rim_dark_str: hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float rim_dark_power: hint_range(0.5, 6.0, 0.1) = 2.2;
uniform float fresnel_str: hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float roughness: hint_range(0.0, 1.0, 0.01) = 0.06;
uniform float specular: hint_range(0.0, 1.0, 0.01) = 0.85;
uniform float base_alpha: hint_range(0.0, 1.0, 0.01) = 0.72;
uniform float clearcoat: hint_range(0.0, 1.0, 0.01) = 0.60;
uniform float clearcoat_rough: hint_range(0.0, 1.0, 0.01) = 0.05;
// 0 = smooth sphere, 1 = fully faceted cut-stone look.
uniform float facet_strength: hint_range(0.0, 1.0, 0.01) = 1.0;

void fragment() {
	// dFdx/dFdy of VERTEX are constant per triangle, so the cross product gives
	// one flat normal per polygon — makes each face reflect like a cut gem facet.
	vec3 flat_n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	flat_n *= sign(dot(flat_n, VIEW));
	vec3 n = normalize(mix(NORMAL, flat_n, facet_strength));
	float nv = max(dot(n, VIEW), 0.0);

	// Schlick fresnel, emerald IOR ~1.57 → R0 = 0.046.
	const float R0 = 0.046;
	float fresnel = R0 + (1.0 - R0) * pow(1.0 - nv, 5.0);

	// Use smooth NORMAL for refraction so the distortion follows the sphere silhouette.
	vec2 distort = NORMAL.xy * (1.0 - nv) * refraction_bend;
	vec3 refracted = texture(SCREEN_TEXTURE, SCREEN_UV + distort).rgb;

	vec3 interior = mix(deep_color.rgb, glow_color.rgb, pow(nv, glow_power));
	interior = mix(interior, refracted * tint_color.rgb * 1.8, (1.0 - nv) * refraction_str);

	float rim_dark = pow(1.0 - nv, rim_dark_power);
	vec3 col = mix(interior, deep_color.rgb * 0.5, rim_dark * rim_dark_str);
	col = mix(col, fresnel_color.rgb, fresnel * fresnel_str);

	// Push the faceted normal into the pipeline so specular/clearcoat snap per-face too.
	NORMAL = n;

	ALBEDO = col;
	METALLIC = 0.0;
	ROUGHNESS = roughness;
	SPECULAR = specular;

	ALPHA = clamp(base_alpha + fresnel * (1.0 - base_alpha), 0.0, 1.0);

	CLEARCOAT = clearcoat;
	CLEARCOAT_ROUGHNESS = clearcoat_rough;
}
