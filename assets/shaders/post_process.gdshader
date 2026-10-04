shader_type canvas_item;
// Vinheta leve + correção de cor quente (grading) para a câmera de trailer e jogo geral.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float warmth : hint_range(0.0, 0.3) = 0.08;
uniform float letterbox : hint_range(0.0, 0.2) = 0.0;

void fragment() {
	vec4 col = textureLod(screen_tex, SCREEN_UV, 0.0);
	vec2 centered = UV * 2.0 - 1.0;
	float dist = length(centered * vec2(1.0, 0.8));
	float vig = smoothstep(0.55, 1.35, dist) * vignette_strength;
	col.rgb *= 1.0 - vig;
	col.rgb += vec3(warmth * 0.6, warmth * 0.3, -warmth * 0.3);
	if (letterbox > 0.0) {
		float bar = step(UV.y, letterbox) + step(1.0 - letterbox, UV.y);
		col.rgb = mix(col.rgb, vec3(0.0), bar);
	}
	COLOR = col;
}
