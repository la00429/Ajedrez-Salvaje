shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;
// Agua de la demo (lagunas, ríos, charcas): oleaje animado con ruido,
// reflejos del cielo y más opacidad en ángulos rasantes.

uniform vec4 deep_color : source_color = vec4(0.08, 0.18, 0.22, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.2, 0.36, 0.38, 1.0);
uniform float wave_speed = 0.35;
uniform float wave_scale = 0.55;
uniform float roughness_value = 0.06;
// Reflectividad: alta en lagunas claras, baja en aguas turbias.
uniform float specular_amount = 0.7;

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

float waves(vec2 p, float t) {
	return value_noise(p + vec2(t, t * 0.6)) * 0.6 + value_noise(p * 2.3 - vec2(t * 0.8, -t * 0.4)) * 0.4;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz * wave_scale;
	float t = TIME * wave_speed;
	float e = 0.06;
	float h0 = waves(p, t);
	float hx = waves(p + vec2(e, 0.0), t);
	float hz = waves(p + vec2(0.0, e), t);
	vec3 n = normalize(vec3((h0 - hx) * 2.5, 1.0, (h0 - hz) * 2.5));
	NORMAL_MAP = vec3(n.x, n.z, n.y) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.7;
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, 3.0);
	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, 0.25 + 0.5 * h0);
	ROUGHNESS = roughness_value;
	SPECULAR = specular_amount;
	ALPHA = mix(0.82, 0.97, fresnel);
}
