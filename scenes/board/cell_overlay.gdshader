shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;
// Capa de resaltado de una casilla 3D: selección, movimientos, capturas,
// jaque, última jugada, cursor encima y tierra quemada (casilla bloqueada).
// Se dibuja como un plano transparente apenas por encima de la casilla.

// 0 ninguno, 1 seleccionada, 2 movimiento, 3 captura, 4 jaque, 5 última jugada
uniform int kind = 0;
uniform bool hovered = false;
uniform bool blocked = false;
uniform vec2 seed = vec2(0.0);

uniform vec4 selected_color : source_color = vec4(1.0, 0.84, 0.37, 1.0);
uniform vec4 move_color : source_color = vec4(0.08, 0.1, 0.06, 0.38);
uniform vec4 capture_color : source_color = vec4(0.88, 0.34, 0.23, 1.0);
uniform vec4 check_color : source_color = vec4(1.0, 0.18, 0.18, 1.0);
uniform vec4 last_move_color : source_color = vec4(1.0, 0.92, 0.45, 0.3);
uniform vec4 hover_color : source_color = vec4(1.0, 1.0, 1.0, 0.14);
uniform vec4 blocked_color : source_color = vec4(0.16, 0.1, 0.06, 1.0);
uniform vec4 ember_color : source_color = vec4(1.0, 0.48, 0.18, 1.0);

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
		p *= 2.07;
		amplitude *= 0.5;
	}
	return total;
}

// Composición "por encima" de dos colores con transparencia.
vec4 over(vec4 dst, vec4 src) {
	float a = src.a + dst.a * (1.0 - src.a);
	vec3 c = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / max(a, 0.0001);
	return vec4(c, a);
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv - 0.5;
	float d = length(p);
	float edge = min(min(uv.x, uv.y), min(1.0 - uv.x, 1.0 - uv.y));
	float pulse = 0.5 + 0.5 * sin(TIME * 4.0);
	vec4 col = vec4(0.0);

	if (kind == 5) {
		col = over(col, last_move_color);
	}
	if (kind == 1) {
		col = over(col, vec4(selected_color.rgb, 0.26 + 0.12 * pulse));
		float border = 1.0 - smoothstep(0.045, 0.06, edge);
		col = over(col, vec4(selected_color.rgb, border * (0.75 + 0.25 * pulse)));
	}
	if (kind == 4) {
		float glow = 1.0 - smoothstep(0.0, 0.62, d);
		col = over(col, vec4(check_color.rgb, glow * (0.6 + 0.4 * pulse)));
	}
	if (blocked) {
		col = over(col, vec4(blocked_color.rgb, 0.86));
		vec2 q = uv * 3.2 + seed;
		float n = fbm(q);
		float n2 = fbm(q * 1.9 + 7.3);
		float crack = 1.0 - smoothstep(0.0, 0.028, abs(n - 0.5));
		crack = max(crack, (1.0 - smoothstep(0.0, 0.02, abs(n2 - 0.5))) * 0.7);
		float glow = 1.0 - smoothstep(0.0, 0.11, abs(n - 0.5));
		float fade = smoothstep(0.0, 0.08, edge);
		col = over(col, vec4(ember_color.rgb, glow * 0.35 * (0.5 + 0.5 * pulse) * fade));
		col = over(col, vec4(mix(ember_color.rgb, vec3(1.0, 0.9, 0.6), 0.3), crack * (0.55 + 0.45 * pulse) * fade));
	}
	if (hovered) {
		col = over(col, hover_color);
		float border = 1.0 - smoothstep(0.012, 0.025, edge);
		col = over(col, vec4(1.0, 1.0, 1.0, border * 0.45));
	}
	if (kind == 2) {
		float r = 0.12 + 0.02 * pulse;
		float halo = 1.0 - smoothstep(r * 1.7 - 0.012, r * 1.7, d);
		float dot_mask = 1.0 - smoothstep(r - 0.012, r, d);
		col = over(col, vec4(move_color.rgb, move_color.a * 0.35 * halo));
		col = over(col, vec4(move_color.rgb, move_color.a * dot_mask));
	}
	if (kind == 3) {
		float s = 0.26;
		float corners = 0.0;
		corners = max(corners, step(uv.x + uv.y, s));
		corners = max(corners, step((1.0 - uv.x) + uv.y, s));
		corners = max(corners, step(uv.x + (1.0 - uv.y), s));
		corners = max(corners, step((1.0 - uv.x) + (1.0 - uv.y), s));
		float ring = 1.0 - smoothstep(0.018, 0.03, abs(d - (0.43 + 0.02 * pulse)));
		col = over(col, vec4(capture_color.rgb, corners * (0.7 + 0.3 * pulse)));
		col = over(col, vec4(capture_color.rgb, ring * 0.6));
	}

	ALBEDO = col.rgb;
	ALPHA = col.a;
}
