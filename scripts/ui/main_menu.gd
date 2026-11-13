extends Node3D
## Menú principal de Ajedrez Salvaje.
##
## De fondo muestra el tablero 3D en un bioma, con la cámara girando despacio
## y el cazador caminando. Pantallas: inicio, elección de nivel, cómo jugar y
## créditos. Se navega con mouse o teclado (flechas, Enter y Esc).
##
## "Jugar" abre [constant GAME_SCENE_PATH] en el bioma del nivel elegido. Por
## ahora es la demo del tablero; cuando exista la escena de juego
## (scenes/main/Main.tscn, integración), basta con cambiar esa ruta. Si la
## escena tiene un método [code]start_level(nivel: int)[/code], el menú lo llama.

const GAME_SCENE_PATH := "res://tests/board/board_demo.tscn"
const DemoPiece := preload("res://tests/board/demo_piece_3d.gd")

## Datos de cada nivel (documento de preproducción, sección 4.3).
const LEVELS := [
	{
		"theme": &"paramo", "place": "NIVEL 1 · RESERVA DE SUMAPAZ", "title": "Páramo en Alerta",
		"text": "Terreno estable y un cazador furtivo en caminata aleatoria.",
		"goal": "Jaque mate, o resistir 15 turnos con agua > 30%.",
	},
	{
		"theme": &"amazonia", "place": "NIVEL 2 · SELVA AMAZÓNICA", "title": "Frente de Deforestación",
		"text": "Olas de calor y una retroexcavadora que tala casillas.",
		"goal": "Jaque mate con más de 4 plantas vivas.",
	},
	{
		"theme": &"santuario", "place": "NIVEL 3 · SANTUARIO MIXTO EN CRISIS", "title": "Colapso Antrópico",
		"text": "Especies invasoras, hipopótamos y cazadores.",
		"goal": "Desarticular al rival con agua > 60%.",
	},
]

## Créditos: completar los nombres de cada integrante.
const CREDITS := [
	["Integrante 1", "Tablero y casillas", "Por definir"],
	["Integrante 2", "Piezas y reglas de ajedrez", "Por definir"],
	["Integrante 3", "Motor de simulación", "Por definir"],
	["Integrante 4", "Biomas e interfaz", "Por definir"],
	["Integrante 5", "Integración y progresión", "Por definir"],
]

const HOW_TO_PLAY := """[color=#d4b45a][b]OBJETIVO[/b][/color]
Eres el Guardián del Bioma. Derrota a la fauna rival y, al mismo tiempo, mantén vivo el ecosistema: si la reserva de agua llega a cero, el bioma colapsa y pierdes.

[color=#d4b45a][b]LAS PIEZAS[/b][/color]
• [b]Frailejón[/b] (peón, 8 por bando): retiene agua. Si cae, entra al vivero y vuelve a brotar.
• [b]Venado de cola blanca[/b] (caballo, 2 por bando): salta en forma de L.
• [b]Frailejón Gran Abuelo[/b] (rey): si cae, el bioma se pierde.
• [b]Cazador furtivo[/b] (neutral): camina al azar y destruye lo que pisa.

[color=#d4b45a][b]CADA TURNO[/b][/color]
1. [b]Clima[/b] (Monte Carlo): estable, lluvia, helada o catástrofe.
2. [b]Agua[/b] (Dinámica de Sistemas): los frailejones aportan; la evaporación y el consumo restan.
3. [b]Vivero[/b] (cola M/M/1): las plantas germinan si el agua supera el 30%.
4. [b]Cazador[/b] (caminata aleatoria 2D): da un paso al norte, sur, este u oeste.
5. [b]Tu jugada[/b]: mueves UNA pieza con las reglas del ajedrez.
6. [b]Rival[/b] (agentes): sus piezas reaccionan a lo que tienen cerca.

[color=#d4b45a][b]CONSEJO[/b][/color]
Protege a tus frailejones: sin ellos el agua no alcanza para llegar al final."""

const PANEL_WIDTH := 470.0
const CREAM := Color("#f1ead8")
const GOLD := Color("#d4b45a")
const MUTED := Color(0.94, 0.92, 0.85, 0.62)
const PIECE_SCALE := 1.3
const CYCLE_SECONDS := 14.0

@onready var board: Board = $Board
@onready var camera: Camera3D = $Camera3D
@onready var environment: Node3D = $Environment
@onready var ui_layer: CanvasLayer = $UI

var _screens := {}
var _current_screen := &"main"
var _theme_name: StringName = &""
var _yaw := deg_to_rad(-25.0)
var _starting := false
var _fade: ColorRect
var _hunter: Node3D
var _rng := RandomNumberGenerator.new()
var _cycle_timer := 0.0
var _hunter_timer := 0.0


func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X
	_rng.randomize()
	board.input_enabled = false
	_build_ui()
	_set_theme(&"paramo")
	_setup_pieces()
	get_viewport().size_changed.connect(_update_camera)
	_update_camera()
	_show_screen(&"main")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screen="):
			_show_screen(StringName(arg.trim_prefix("--screen=")))
	# Aparece desde negro.
	_fade.color.a = 1.0
	create_tween().tween_property(_fade, "color:a", 0.0, 0.9)


func _process(delta: float) -> void:
	_yaw += delta * 0.05
	_update_camera()
	_hunter_timer += delta
	if _hunter_timer > 3.2:
		_hunter_timer = 0.0
		_hunter_step()
	if _current_screen == &"main" and not _starting:
		_cycle_timer += delta
		if _cycle_timer > CYCLE_SECONDS:
			_cycle_timer = 0.0
			var index := LEVELS.map(func(l): return l["theme"]).find(_theme_name)
			_preview_theme(LEVELS[(index + 1) % LEVELS.size()]["theme"])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _current_screen != &"main" and not _starting:
		_show_screen(&"main")
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Fondo: tablero, bioma y cámara
# ---------------------------------------------------------------------------

func _update_camera() -> void:
	var pitch := deg_to_rad(30.0)
	var distance := 19.0
	var target := Vector3(0.0, 0.0, 0.0)
	camera.position = target + Vector3(sin(_yaw) * cos(pitch), sin(pitch), cos(_yaw) * cos(pitch)) * distance
	camera.look_at(target, Vector3.UP)
	# Corre el tablero hacia la derecha para dejar espacio al menú.
	var viewport := get_viewport().get_visible_rect().size
	var visible_width := 2.0 * distance * tan(deg_to_rad(camera.fov) * 0.5) * viewport.x / viewport.y
	var free_center := (PANEL_WIDTH + 80.0 + viewport.x) * 0.5
	camera.h_offset = -(free_center - viewport.x * 0.5) / viewport.x * visible_width


func _set_theme(theme_name: StringName) -> void:
	_theme_name = theme_name
	board.board_theme = BoardTheme.create(theme_name)
	environment.apply_preset(theme_name)


## Cambia el bioma de fondo con un fundido breve.
func _preview_theme(theme_name: StringName) -> void:
	if theme_name == _theme_name or _starting:
		return
	_theme_name = theme_name
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.55, 0.2)
	tween.tween_callback(_set_theme.bind(theme_name))
	tween.tween_property(_fade, "color:a", 0.0, 0.35)


func _setup_pieces() -> void:
	for x in Board.SIZE:
		_spawn(0, &"pawn", Vector2i(x, 1))
		_spawn(1, &"pawn", Vector2i(x, 6))
	for x in [1, 6]:
		_spawn(0, &"knight", Vector2i(x, 0))
		_spawn(1, &"knight", Vector2i(x, 7))
	_spawn(0, &"king", Vector2i(4, 0))
	_spawn(1, &"king", Vector2i(4, 7))
	_hunter = _spawn(-1, &"hunter", Vector2i(3, 3))


func _spawn(side: int, kind: StringName, coord: Vector2i) -> Node3D:
	var piece := DemoPiece.new()
	piece.side = side
	piece.kind = kind
	piece.scale = Vector3.ONE * PIECE_SCALE
	board.place_piece(piece, coord)
	return piece


## El cazador pasea por casillas libres (sin destruir nada en el menú).
func _hunter_step() -> void:
	var from := board.find_piece(_hunter)
	var options := Board.get_orthogonal_neighbors(from).filter(func(c: Vector2i) -> bool: return board.is_empty(c))
	if not options.is_empty():
		board.move_piece(from, options[_rng.randi() % options.size()])


# ---------------------------------------------------------------------------
# Navegación
# ---------------------------------------------------------------------------

func _show_screen(screen_name: StringName) -> void:
	_current_screen = screen_name
	for key in _screens:
		var screen: Control = _screens[key]
		screen.visible = key == screen_name
	var screen: Control = _screens[screen_name]
	screen.modulate.a = 0.0
	create_tween().tween_property(screen, "modulate:a", 1.0, 0.25)
	var first := _first_focusable(screen)
	if first:
		first.grab_focus.call_deferred()


func _first_focusable(node: Node) -> Control:
	for child in node.get_children():
		if child is BaseButton:
			return child
		var found := _first_focusable(child)
		if found:
			return found
	return null


## Abre la escena de juego en el bioma del nivel elegido (1, 2 o 3).
func start_level(level: int) -> void:
	if _starting:
		return
	_starting = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(_fade, "color:a", 1.0, 0.6)
	tween.tween_callback(_open_game.bind(level))


func _open_game(level: int) -> void:
	var packed: PackedScene = load(GAME_SCENE_PATH)
	var game := packed.instantiate()
	if "initial_theme" in game:
		game.initial_theme = LEVELS[level - 1]["theme"]
	var tree := get_tree()
	tree.root.add_child(game)
	tree.current_scene = game
	if game.has_method("start_level"):
		game.start_level(level)
	queue_free()


func _quit() -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.4)
	tween.tween_callback(get_tree().quit)


# ---------------------------------------------------------------------------
# Construcción de la interfaz
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Degradado oscuro a la izquierda para que el texto se lea sobre el paisaje.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.02, 0.03, 0.02, 0.9))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	gradient.add_point(0.45, Color(0.02, 0.03, 0.02, 0.7))
	var shade_texture := GradientTexture2D.new()
	shade_texture.gradient = gradient
	shade_texture.width = 256
	shade_texture.height = 4
	var shade := TextureRect.new()
	shade.texture = shade_texture
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.anchor_bottom = 1.0
	shade.anchor_right = 0.75
	ui_layer.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	ui_layer.add_child(margin)

	_screens[&"main"] = _build_main_screen()
	_screens[&"levels"] = _build_levels_screen()
	_screens[&"how"] = _build_how_screen()
	_screens[&"credits"] = _build_credits_screen()
	for key in _screens:
		margin.add_child(_screens[key])

	var footer := _label("ExpoSimu 2026 · Simulación por Computador", 12, MUTED)
	footer.autowrap_mode = TextServer.AUTOWRAP_OFF
	footer.custom_minimum_size.x = 0
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_left = 72.0
	footer.offset_top = -30.0
	footer.offset_bottom = -12.0
	ui_layer.add_child(footer)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_fade)


func _screen() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = PANEL_WIDTH
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	return box


func _build_main_screen() -> Control:
	var box := _screen()
	var title := _label("AJEDREZ\nSALVAJE", 74, CREAM)
	title.add_theme_constant_override("line_spacing", -18)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	box.add_child(title)
	box.add_child(_label("Biomas de Colombia", 24, GOLD))
	box.add_child(_label("Estrategia por turnos sobre un ecosistema vivo: ajedrez, clima, agua y fauna simulados.", 15, MUTED))
	box.add_child(_spacer(22))
	for entry in [["Jugar", _show_screen.bind(&"levels")], ["Cómo jugar", _show_screen.bind(&"how")],
			["Créditos", _show_screen.bind(&"credits")], ["Salir", _quit]]:
		var button := _menu_button(entry[0])
		button.pressed.connect(entry[1])
		box.add_child(button)
	return box


func _build_levels_screen() -> Control:
	var box := _screen()
	box.add_child(_label("Elige un bioma", 34, CREAM))
	box.add_child(_label("Cada nivel usa los mismos modelos de simulación con parámetros distintos.", 14, MUTED))
	box.add_child(_spacer(6))
	for i in LEVELS.size():
		box.add_child(_level_card(i))
	box.add_child(_spacer(6))
	var back := _menu_button("Volver")
	back.pressed.connect(_show_screen.bind(&"main"))
	box.add_child(back)
	return box


## Tarjeta de nivel: un contenedor que toma el alto de su texto, con un botón
## detrás que recibe el clic y el foco del teclado.
func _level_card(index: int) -> Control:
	var level: Dictionary = LEVELS[index]
	var card := MarginContainer.new()
	card.custom_minimum_size.x = PANEL_WIDTH
	var button := Button.new()
	button.focus_mode = Control.FOCUS_ALL
	_style_button(button, Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.12), 12)
	button.mouse_entered.connect(_preview_theme.bind(level["theme"]))
	button.focus_entered.connect(_preview_theme.bind(level["theme"]))
	button.pressed.connect(start_level.bind(index + 1))
	card.add_child(button)

	var padding := MarginContainer.new()
	padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		padding.add_theme_constant_override("margin_" + side, 18)
	for side in ["top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 12)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows := [[level["place"], 12, GOLD], [level["title"], 22, CREAM], [level["text"], 14, MUTED],
			["Victoria: " + level["goal"], 14, Color("#b9d99a")]]
	for row in rows:
		var label := _label(row[0], row[1], row[2])
		label.custom_minimum_size.x = PANEL_WIDTH - 36.0
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
	padding.add_child(content)
	card.add_child(padding)
	return card


func _build_how_screen() -> Control:
	var box := _screen()
	box.add_child(_label("Cómo jugar", 34, CREAM))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(PANEL_WIDTH, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.custom_minimum_size.x = PANEL_WIDTH - 16.0
	text.add_theme_font_size_override("normal_font_size", 15)
	text.add_theme_font_size_override("bold_font_size", 15)
	text.add_theme_color_override("default_color", Color(CREAM, 0.9))
	text.add_theme_constant_override("line_separation", 3)
	text.text = HOW_TO_PLAY
	scroll.add_child(text)
	box.add_child(scroll)
	var back := _menu_button("Volver")
	back.pressed.connect(_show_screen.bind(&"main"))
	box.add_child(back)
	return box


func _build_credits_screen() -> Control:
	var box := _screen()
	box.add_child(_label("Créditos", 34, CREAM))
	box.add_child(_label("Proyecto final de Simulación por Computador · ExpoSimu 2026", 14, MUTED))
	box.add_child(_spacer(8))
	for credit in CREDITS:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		row.add_child(_label("%s · %s" % [credit[0], credit[1]], 13, GOLD))
		row.add_child(_label(credit[2], 20, CREAM))
		box.add_child(row)
	box.add_child(_spacer(8))
	box.add_child(_label("Modelos: colas M/M/1, caminata aleatoria 2D, Monte Carlo, agentes y dinámica de sistemas.", 13, MUTED))
	var back := _menu_button("Volver")
	back.pressed.connect(_show_screen.bind(&"main"))
	box.add_child(back)
	return box


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Con ancho fijo desde el inicio, el salto de línea no infla la altura.
	label.custom_minimum_size.x = PANEL_WIDTH
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	return spacer


func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(300, 48)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size", 20)
	_style_button(button, Color(1, 1, 1, 0.05), GOLD, 10)
	return button


func _style_button(button: Button, normal: Color, highlight: Color, radius: int) -> void:
	var states := {"normal": normal, "hover": highlight, "focus": highlight, "pressed": highlight.darkened(0.15)}
	for state in states:
		var box := StyleBoxFlat.new()
		box.bg_color = states[state]
		box.set_corner_radius_all(radius)
		box.content_margin_left = 22
		box.content_margin_right = 22
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		if state == "focus" or state == "hover":
			box.border_color = Color(GOLD, 0.9)
			box.set_border_width_all(2 if highlight != GOLD else 0)
		button.add_theme_stylebox_override(state, box)
	var dark_text := highlight == GOLD
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color("#1d1a14") if dark_text else Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color("#1d1a14") if dark_text else Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("#1d1a14") if dark_text else Color.WHITE)
