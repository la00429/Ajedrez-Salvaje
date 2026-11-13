shader_type spatial;
// Madera para el marco del tablero: vetas alargadas en la dirección de la
// pieza ([grain_dir]) con variaciones suaves, sobre el color del marco.

uniform vec4 base_color : source_color = vec4(0.29, 0.23, 0.17, 1.0);
// Dirección de la veta en el plano XZ (1,0 = a lo largo de X).
uniform vec2 grain_dir = vec2(1.0, 0.0);
uniform float grain_scale = 1.0;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.5;

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
	for (int i = 0; i < 4; i++) {
		total += value_noise(p) * amplitude;
		p *= 2.02;
		amplitude *= 0.5;
	}
	return total;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 dir = normalize(grain_dir);
	vec2 across = vec2(-dir.y, dir.x);
	// A lo largo de la veta el ruido cambia poco; a lo ancho, mucho.
	float along = dot(world_pos.xz, dir) * 0.7 * grain_scale;
	float side = (dot(world_pos.xz, across) + world_pos.y * 0.8) * 9.0 * grain_scale;
	float warp = fbm(vec2(along * 0.6, side * 0.15)) * 3.0;
	float rings = fract(side * 0.35 + warp);
	float streak = smoothstep(0.0, 0.5, rings) * smoothstep(1.0, 0.6, rings);
	float fine = value_noise(vec2(along * 6.0, side * 2.0));
	float shade = 0.82 + 0.16 * streak + 0.08 * (fine - 0.5);
	ALBEDO = base_color.rgb * shade;
	ROUGHNESS = roughness_value + (1.0 - streak) * 0.12;
	SPECULAR = 0.35;
}
