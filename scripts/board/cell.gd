class_name Cell
extends Node3D
## Casilla individual del tablero 3D de Ajedrez Salvaje.
##
## Se encarga solo de su representación: un bloque (la casilla) y un plano
## transparente encima para los resaltados. No sabe nada de piezas ni de
## reglas: el [Board] la crea, la posiciona y le indica cómo mostrarse.
##
## El origen del nodo es el centro de la cara superior de la casilla (y = 0).

## Tipos de resaltado que puede mostrar una casilla.
enum Highlight {
	NONE, ## Sin resaltado.
	SELECTED, ## Casilla de la pieza seleccionada.
	MOVE, ## Destino válido vacío (punto).
	CAPTURE, ## Destino válido con captura (esquinas y anillo).
	CHECK, ## Rey en jaque (resplandor rojo).
	LAST_MOVE, ## Origen o destino de la última jugada.
}

## Grosor del bloque de la casilla, como fracción del lado.
const TILE_HEIGHT := 0.12
## Separación entre casillas (las juntas), como fracción del lado.
const TILE_GAP := 0.035

const OVERLAY_SHADER := preload("res://scenes/board/cell_overlay.gdshader")

## Coordenada lógica: columna 0-7 (a-h), fila 0-7 (1-8).
var coord := Vector2i.ZERO
## Lado de la casilla en unidades del mundo.
var cell_size := 1.0
## true si es casilla clara. Como en el ajedrez real, a1 es oscura.
var is_light := false
## Tema con los colores de resaltado y efectos.
var board_theme: BoardTheme
## Material propio para esta casilla (por ejemplo, una textura del bioma).
## Si es null se usa el material compartido del tablero.
var custom_material: Material:
	set(value):
		custom_material = value
		_apply_material()
## Bloque visible de la casilla.
var tile: MeshInstance3D
## Resaltado actual de la casilla.
var highlight: Highlight = Highlight.NONE:
	set(value):
		highlight = value
		_update_overlay()
## true mientras el cursor está sobre la casilla.
var hovered := false:
	set(value):
		hovered = value
		_update_overlay()
## Marca visual de casilla intransitable (catástrofe, tala...). El tablero no
## impide mover piezas aquí: las reglas de movimiento consultan este estado.
var blocked := false:
	set(value):
		blocked = value
		_update_overlay()

var _shared_material: Material
var _overlay: MeshInstance3D
var _overlay_material := ShaderMaterial.new()


func _init() -> void:
	tile = MeshInstance3D.new()
	tile.name = "Tile"
	tile.mesh = BoxMesh.new()
	add_child(tile, false, Node.INTERNAL_MODE_FRONT)

	_overlay_material.shader = OVERLAY_SHADER
	_overlay = MeshInstance3D.new()
	_overlay.name = "Overlay"
	_overlay.mesh = PlaneMesh.new()
	_overlay.material_override = _overlay_material
	_overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_overlay.visible = false
	add_child(_overlay, false, Node.INTERNAL_MODE_FRONT)


## Configura la casilla. Lo llama el [Board] al construir o refrescar el tablero.
func setup(p_coord: Vector2i, p_size: float, p_is_light: bool, p_material: Material, p_theme: BoardTheme) -> void:
	coord = p_coord
	cell_size = p_size
	is_light = p_is_light
	board_theme = p_theme
	_shared_material = p_material

	var width := p_size * (1.0 - TILE_GAP)
	(tile.mesh as BoxMesh).size = Vector3(width, p_size * TILE_HEIGHT, width)
	tile.position.y = -p_size * TILE_HEIGHT * 0.5
	_apply_material()

	(_overlay.mesh as PlaneMesh).size = Vector2(width, width)
	_overlay.position.y = p_size * 0.004
	_overlay_material.set_shader_parameter(&"seed", Vector2(coord) * 1.37 + Vector2(0.31, 0.77))
	_overlay_material.set_shader_parameter(&"selected_color", p_theme.selected_color)
	_overlay_material.set_shader_parameter(&"move_color", p_theme.move_color)
	_overlay_material.set_shader_parameter(&"capture_color", p_theme.capture_color)
	_overlay_material.set_shader_parameter(&"check_color", p_theme.check_color)
	_overlay_material.set_shader_parameter(&"last_move_color", p_theme.last_move_color)
	_overlay_material.set_shader_parameter(&"hover_color", p_theme.hover_color)
	_overlay_material.set_shader_parameter(&"blocked_color", p_theme.blocked_color)
	_overlay_material.set_shader_parameter(&"ember_color", p_theme.ember_color)
	_update_overlay()


func _apply_material() -> void:
	tile.material_override = custom_material if custom_material else _shared_material


func _update_overlay() -> void:
	_overlay_material.set_shader_parameter(&"kind", int(highlight))
	_overlay_material.set_shader_parameter(&"hovered", hovered)
	_overlay_material.set_shader_parameter(&"blocked", blocked)
	_overlay.visible = highlight != Highlight.NONE or hovered or blocked
