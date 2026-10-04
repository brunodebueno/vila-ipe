shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx, world_vertex_coords;
// Tufos de grama em MultiMesh: balançam com o vento (uniform global, atualizado por grass_decor.gd).

uniform vec4 color_base : source_color = vec4(0.25, 0.55, 0.18, 1.0);
uniform vec4 color_tip : source_color = vec4(0.55, 0.82, 0.30, 1.0);
uniform float wind_strength = 0.3;
uniform float wind_speed = 1.6;

void vertex() {
	float lean = clamp(VERTEX.y, 0.0, 1.0);
	float phase = dot(MODEL_MATRIX[3].xz, vec2(0.7, 0.3));
	float sway = sin(TIME * wind_speed + phase) * wind_strength * 0.18;
	VERTEX.x += sway * lean * lean;
	VERTEX.z += sway * 0.6 * lean * lean;
}

void fragment() {
	float h = clamp(UV.y, 0.0, 1.0);
	ALBEDO = mix(color_base.rgb, color_tip.rgb, h);
	ROUGHNESS = 0.9;
}
