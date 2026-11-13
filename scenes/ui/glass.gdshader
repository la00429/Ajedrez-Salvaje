shader_type canvas_item;
// Vidrio esmerilado para los paneles de la interfaz: desenfoca lo que hay
// detrás (la escena 3D), lo oscurece un poco para que el texto se lea y
// dibuja un borde fino.
//
// El panel se dibuja con una caja (StyleBoxFlat) que sirve de máscara: el
// fondo en negro opaco y el borde en blanco. El shader usa el canal alfa
// como forma del panel y el canal rojo para saber dónde va el borde.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
// Radio del desenfoque, en píxeles de pantalla.
uniform float blur_radius = 14.0;
// Cuánto se oscurece el fondo (1 = nada).
uniform float darken = 0.6;
// Velo claro sobre el vidrio.
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.07);
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 0.38);
uniform float saturation = 1.15;

void fragment() {
	float mask = COLOR.a;
	float border = COLOR.r;
	vec3 sum = vec3(0.0);
	// 24 muestras en espiral (ángulo áureo) para un desenfoque suave.
	for (int i = 0; i < 24; i++) {
		float fi = float(i);
		float radius = sqrt((fi + 0.5) / 24.0) * blur_radius;
		float angle = fi * 2.39996;
		vec2 offset = vec2(cos(angle), sin(angle)) * radius * SCREEN_PIXEL_SIZE;
		sum += texture(screen_texture, SCREEN_UV + offset).rgb;
	}
	vec3 blurred = sum / 24.0;
	float luma = dot(blurred, vec3(0.299, 0.587, 0.114));
	blurred = mix(vec3(luma), blurred, saturation) * darken;
	vec3 glass = mix(blurred, tint.rgb, tint.a);
	vec3 color = mix(glass, border_color.rgb, border * border_color.a);
	COLOR = vec4(color, mask);
}
