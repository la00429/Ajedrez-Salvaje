shader_type spatial;
render_mode diffuse_burley;
// Terreno de la demo: color por vértice (pasto, roca, orillas...) con detalle
// de ruido y sombras de nubes que se desplazan con el viento.

uniform float detail_strength : hint_range(0.0, 0.6) = 0.2;
uniform float cloud_shadow_strength : hint_range(0.0, 1.0) = 0.3;
uniform vec2 wind = vec2(0.8, 0.35);

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
		p *= 2.03;
		amplitude *= 0.5;
	}
	return total;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = COLOR.rgb;
	float broad = fbm(world_pos.xz * 0.35);
	float grain = value_noise(world_pos.xz * 4.0);
	vec3 col = base * (1.0 + (broad - 0.5) * detail_strength * 2.0 + (grain - 0.5) * detail_strength * 0.7);
	float clouds = smoothstep(0.48, 0.78, fbm(world_pos.xz * 0.03 + TIME * wind * 0.012));
	col *= 1.0 - clouds * cloud_shadow_strength;
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
