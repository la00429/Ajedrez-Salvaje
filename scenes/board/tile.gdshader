shader_type spatial;
// Textura orgánica de las casillas 3D: ruido fractal (musgo, tierra, arena)
// sobre el color de la casilla. El ruido usa la posición en el mundo, así que
// cada casilla tiene un dibujo distinto aunque compartan el material.

uniform vec4 base_color : source_color = vec4(1.0);
uniform float texture_strength : hint_range(0.0, 0.6) = 0.14;
uniform float texture_scale : hint_range(0.05, 6.0) = 1.6;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.85;

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
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		total += value_noise(p) * amplitude;
		p *= 2.03;
		amplitude *= 0.5;
	}
	return total;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz + vec2(world_pos.y * 3.1, -world_pos.y * 1.7);
	float broad = fbm(p * texture_scale);
	float grain = value_noise(p * texture_scale * 9.0);
	float shade = 1.0 + (broad - 0.5) * texture_strength * 2.2 + (grain - 0.5) * texture_strength * 0.8;
	ALBEDO = base_color.rgb * shade;
	ROUGHNESS = clamp(roughness_value - grain * 0.12, 0.0, 1.0);
	SPECULAR = 0.3;
}
