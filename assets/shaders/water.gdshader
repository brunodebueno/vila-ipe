shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;
// Água estilizada: ondas Gerstner leves no vértice, cor turquesa, espuma animada, fresnel do céu.

uniform vec4 shallow_color : source_color = vec4(0.22, 0.85, 0.78, 0.55);
uniform vec4 deep_color : source_color = vec4(0.03, 0.32, 0.52, 0.92);
uniform float wave_speed = 0.6;
uniform float depth_scale = 1.4;
uniform float wave_height = 0.06;
uniform float fresnel_power = 3.0;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

varying vec2 world_xz;
varying vec3 world_normal;

vec3 gerstner(vec2 pos, float t, vec2 dir, float wavelength, float amp, float speed) {
	float k = TAU / wavelength;
	float phase = dot(normalize(dir), pos) * k + t * speed * k;
	float s = sin(phase);
	return vec3(0.0, amp * s, 0.0);
}

void vertex() {
	vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	world_xz = world_pos.xz;
	float t = TIME * wave_speed;
	vec3 offset = vec3(0.0);
	offset += gerstner(world_xz, t, vec2(1.0, 0.3), 6.0, wave_height, 1.0);
	offset += gerstner(world_xz, t, vec2(-0.4, 1.0), 3.2, wave_height * 0.6, 1.4);
	offset += gerstner(world_xz, t, vec2(0.7, -0.6), 1.6, wave_height * 0.3, 2.1);
	VERTEX += offset;
	float eps = 0.1;
	float h0 = offset.y;
	float hx = gerstner(world_xz + vec2(eps, 0.0), t, vec2(1.0, 0.3), 6.0, wave_height, 1.0).y;
	float hz = gerstner(world_xz + vec2(0.0, eps), t, vec2(1.0, 0.3), 6.0, wave_height, 1.0).y;
	world_normal = normalize(vec3((h0 - hx) / eps, 1.0, (h0 - hz) / eps));
	NORMAL = world_normal;
}

void fragment() {
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float thickness = max(VERTEX.z - view.z, 0.0);

	float t = clamp(thickness / depth_scale, 0.0, 1.0);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, t);
	float alpha = mix(shallow_color.a, deep_color.a, t);

	float foam_edge = 1.0 - smoothstep(0.0, 0.28, thickness);
	float foam_wave = sin(world_xz.x * 2.4 + TIME * wave_speed * 2.6) * 0.5 + sin(world_xz.y * 2.0 - TIME * wave_speed * 2.1) * 0.5;
	float foam = foam_edge * (0.5 + 0.5 * smoothstep(-0.2, 0.6, foam_wave));
	float ripple = sin(world_xz.x * 2.0 + TIME * wave_speed * 2.0) * 0.5 + sin(world_xz.y * 2.3 - TIME * wave_speed * 1.7) * 0.5;
	col += ripple * 0.02 + foam * 0.65;

	vec3 view_dir = normalize(VIEW);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, view_dir), 0.0, 1.0), fresnel_power);
	vec3 sky_tint = vec3(0.55, 0.72, 0.9);
	col = mix(col, sky_tint, fresnel * 0.5);

	ALBEDO = col;
	ALPHA = clamp(max(alpha, foam * 0.9), 0.0, 1.0);
	ROUGHNESS = 0.05;
	SPECULAR = 0.85;
}
