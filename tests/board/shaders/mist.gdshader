shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Capa de niebla o nubes: ruido fractal que se desplaza lentamente.
// Se desvanece cerca del centro (para no tapar el tablero) y en el borde.

uniform vec4 tint : source_color = vec4(1.0);
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float scale = 0.05;
uniform vec2 drift = vec2(0.012, 0.005);
uniform float inner_radius = 9.0;
uniform float outer_radius = 80.0;
uniform float coverage : hint_range(0.0, 1.0) = 0.45;

varying vec3 world_pos;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		total += value_noise(p) * amplitude;
		p *= 2.07;
		amplitude *= 0.5;
	}
	return total;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = fbm(world_pos.xz * scale + TIME * drift);
	float a = smoothstep(coverage, coverage + 0.3, n) * density;
	float r = length(world_pos.xz);
	a *= smoothstep(inner_radius, inner_radius + 8.0, r);
	a *= 1.0 - smoothstep(outer_radius * 0.65, outer_radius, r);
	ALBEDO = tint.rgb;
	ALPHA = a;
}
