shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// Matas de pasto (MultiMesh) que se mecen con el viento. La malla mide 1 de
// alto: la base queda quieta y la punta se mueve más. El color de cada
// instancia (COLOR) varía el tono.

uniform vec4 base_color : source_color = vec4(0.35, 0.33, 0.18, 1.0);
uniform vec4 tip_color : source_color = vec4(0.78, 0.72, 0.45, 1.0);
uniform float sway = 0.14;
uniform float wind_speed = 1.4;

varying float blade_height;

void vertex() {
	blade_height = clamp(VERTEX.y, 0.0, 1.0);
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float t = TIME * wind_speed + origin.x * 0.31 + origin.z * 0.23;
	float gust = 0.6 + 0.4 * sin(TIME * 0.37 + origin.x * 0.05);
	float bend = blade_height * blade_height * sway * gust;
	VERTEX.x += sin(t) * bend;
	VERTEX.z += cos(t * 0.83) * bend * 0.6;
	// Normales hacia arriba: el pasto se ilumina como una alfombra suave.
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.7));
}

void fragment() {
	vec3 col = mix(base_color.rgb, tip_color.rgb, blade_height) * COLOR.rgb;
	ALBEDO = col;
	ROUGHNESS = 0.9;
	SPECULAR = 0.15;
	BACKLIGHT = col * 0.35;
}
