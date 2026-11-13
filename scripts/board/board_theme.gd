class_name BoardTheme
extends Resource
## Apariencia del tablero: colores de casillas, marco, resaltados y efectos.
##
## [method create] devuelve los temas predefinidos de cada bioma. El módulo de
## biomas puede usarlos tal cual o guardar variantes propias como [code].tres[/code].

const PRESETS: Array[StringName] = [&"paramo", &"amazonia", &"santuario", &"clasico"]

@export var display_name := "Páramo"

@export_group("Casillas")
@export var light_color := Color("#cfd2b2")
@export var dark_color := Color("#738a62")
## Intensidad de la textura orgánica de las casillas (0 = color plano).
@export_range(0.0, 0.6, 0.01) var texture_strength := 0.16
## Frecuencia del grano de la textura por unidad de tablero (más alto = más fino).
@export_range(0.05, 6.0, 0.05) var texture_scale := 1.6
@export_range(0.0, 1.0, 0.01) var tile_roughness := 0.85

@export_group("Marco")
@export var frame_color := Color("#4a3a2c")
@export var frame_accent_color := Color("#c9c5a8")
@export var label_color := Color("#e9e5cf")
## Ancho del marco como fracción del lado de una casilla (0 = sin marco).
@export_range(0.0, 1.0, 0.01) var frame_ratio := 0.5
## Altura del borde del marco sobre las casillas, como fracción de una casilla.
@export_range(0.0, 0.5, 0.01) var frame_height := 0.1

@export_group("Resaltados")
@export var selected_color := Color("#ffd75e")
@export var move_color := Color(0.08, 0.1, 0.06, 0.45)
@export var capture_color := Color("#e0563b")
@export var check_color := Color("#ff2e2e")
@export var last_move_color := Color(1.0, 0.92, 0.45, 0.32)
@export var hover_color := Color(1.0, 1.0, 1.0, 0.16)

@export_group("Bloqueo y efectos")
## Color de la tierra quemada en casillas bloqueadas.
@export var blocked_color := Color("#2a1a10")
## Color de las grietas encendidas en casillas bloqueadas.
@export var ember_color := Color("#ff7a2e")
## Color del polvo que aparece al retirar una pieza.
@export var effect_color := Color("#e9e5cf")


## Crea uno de los temas predefinidos: [code]&"paramo"[/code], [code]&"amazonia"[/code],
## [code]&"santuario"[/code] o [code]&"clasico"[/code].
static func create(preset: StringName) -> BoardTheme:
	var t := BoardTheme.new()
	match preset:
		&"amazonia":
			t.display_name = "Amazonía"
			t.light_color = Color("#d9c58f")
			t.dark_color = Color("#3e6b3a")
			t.texture_strength = 0.2
			t.frame_color = Color("#3a2a1a")
			t.frame_accent_color = Color("#c9a046")
			t.label_color = Color("#f1e3b5")
			t.selected_color = Color("#ffd23f")
			t.effect_color = Color("#a4d17a")
		&"santuario":
			t.display_name = "Santuario"
			t.light_color = Color("#d4bf9c")
			t.dark_color = Color("#6f6a4c")
			t.texture_strength = 0.22
			t.frame_color = Color("#36302c")
			t.frame_accent_color = Color("#b5562f")
			t.label_color = Color("#eadbc4")
			t.selected_color = Color("#ffb347")
			t.effect_color = Color("#d9a07a")
		&"clasico":
			t.display_name = "Clásico"
			t.light_color = Color("#f0d9b5")
			t.dark_color = Color("#b58863")
			t.texture_strength = 0.08
			t.tile_roughness = 0.6
			t.frame_color = Color("#4a3324")
			t.frame_accent_color = Color("#d8b07a")
			t.label_color = Color("#f0d9b5")
		_:
			pass # Los valores por defecto son los del Páramo (nivel 1).
	return t
