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
const UiStyle := preload("res://scripts/ui/ui_style.gd")

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
• [b]Frailejón[/b] (peón, 8): retiene agua. Si cae, entra al vivero y vuelve a brotar.
• [b]Venado de cola blanca[/b] (caballo, 2): salta en forma de L.
• [b]Cóndor andino[/b] (alfil, 2): vuela en diagonal.
• [b]Oso de anteojos[/b] (torre, 2): avanza por filas y columnas.
• [b]Danta de montaña[/b] (dama, 1): se mueve en todas las direcciones.
• [b]Frailejón Gran Abuelo[/b] (rey, 1): si recibe jaque mate o lo alcanza el cazador, el bioma se pierde.
• [b]Cazador furtivo[/b] (neutral): camina al azar y destruye lo que pisa. Bloquea el paso y no se puede capturar.

[color=#d4b45a][b]CADA TURNO[/b][/color]
1. [b]Clima[/b] (Monte Carlo): estable, lluvia, helada o catástrofe.
2. [b]Agua[/b] (Dinámica de Sistemas): los frailejones aportan; la evaporación y el consumo restan.
3. [b]Vivero[/b] (cola M/M/1): las plantas germinan si el agua supera el 30%.
4. [b]Cazador[/b] (caminata aleatoria 2D): da un paso al norte, sur, este u oeste.
5. [b]Tu jugada[/b]: mueves UNA pieza con las reglas del ajedrez FIDE (incluye enroque, captura al paso y coronación).
6. [b]Rival[/b] (agentes): sus piezas reaccionan a lo que tienen cerca.

[color=#d4b45a][b]CONSEJO[/b][/color]
Protege a tus frailejones: sin ellos el agua no alcanza para llegar al final."""

const PANEL_WIDTH := 470.0
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
var _ui_root: Control
var _subtitle: Label
var _how_text: RichTextLabel


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
	# La interfaz toma los colores del marco del tablero de este bioma.
	UiStyle.apply(_ui_root.theme, board.board_theme)
	_subtitle.add_theme_color_override("font_color", UiStyle.accent(board.board_theme))
	_how_text.add_theme_color_override("default_color", UiStyle.text(board.board_theme))


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
	ChessMatch.new(board).setup_initial(ChessPosition.START_FEN, PIECE_SCALE)
	_hunter = ChessPiece.create(ChessPiece.Kind.HUNTER, ChessPiece.Team.NEUTRAL)
	_hunter.scale = Vector3.ONE * PIECE_SCALE
	board.place_piece(_hunter, Vector2i(3, 3))


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
	_ui_root = Control.new()
	_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.theme = UiStyle.build(BoardTheme.new())
	ui_layer.add_child(_ui_root)

	# Degradado oscuro a la izquierda para que el texto se lea sobre el paisaje.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.02, 0.03, 0.02, 0.88))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	gradient.add_point(0.45, Color(0.02, 0.03, 0.02, 0.66))
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
	_ui_root.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(margin)

	_screens[&"main"] = _build_main_screen()
	_screens[&"levels"] = _build_levels_screen()
	_screens[&"how"] = _build_how_screen()
	_screens[&"credits"] = _build_credits_screen()
	for key in _screens:
		margin.add_child(_screens[key])

	var footer := _label("EXPOSIMU 2026 · SIMULACIÓN POR COMPUTADOR", &"Heading")
	footer.autowrap_mode = TextServer.AUTOWRAP_OFF
	footer.custom_minimum_size.x = 0
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_left = 72.0
	footer.offset_top = -30.0
	footer.offset_bottom = -12.0
	footer.modulate.a = 0.75
	_ui_root.add_child(footer)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(_fade)


func _screen() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = PANEL_WIDTH
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	return box


## Panel de vidrio esmerilado. Devuelve [panel, contenido].
func _plaque(separation: int = 6) -> Array:
	var panel := UiStyle.glass_panel(Color(1, 1, 1, 0.38), 16)
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	panel.add_child(box)
	return [panel, box]


func _build_main_screen() -> Control:
	var box := _screen()
	var title := _label("AJEDREZ\nSALVAJE", &"Display", 72)
	title.add_theme_constant_override("line_spacing", -14)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	box.add_child(title)
	_subtitle = _label("BIOMAS DE COLOMBIA", &"Heading", 15)
	box.add_child(_subtitle)
	var tagline := _label("Estrategia por turnos sobre un ecosistema vivo: ajedrez, clima, agua y fauna simulados.", &"")
	tagline.add_theme_font_size_override("font_size", 15)
	tagline.modulate.a = 0.8
	box.add_child(tagline)
	box.add_child(_spacer(18))
	for entry in [["Jugar", _show_screen.bind(&"levels")], ["Cómo jugar", _show_screen.bind(&"how")],
			["Créditos", _show_screen.bind(&"credits")], ["Salir", _quit]]:
		var button := _menu_button(entry[0])
		button.pressed.connect(entry[1])
		box.add_child(button)
	return box


func _build_levels_screen() -> Control:
	var box := _screen()
	box.add_child(_label("Elige un bioma", &"Display", 40))
	box.add_child(_label("CADA NIVEL USA LOS MISMOS MODELOS CON PARÁMETROS DISTINTOS", &"Heading"))
	box.add_child(_spacer(4))
	for i in LEVELS.size():
		box.add_child(_level_card(i))
	box.add_child(_spacer(4))
	var back := _menu_button("Volver")
	back.pressed.connect(_show_screen.bind(&"main"))
	box.add_child(back)
	return box


## Tarjeta de nivel: vidrio de fondo, un botón transparente que recibe el clic
## y el foco del teclado, y el texto encima. Toma el alto de su texto.
func _level_card(index: int) -> Control:
	var level: Dictionary = LEVELS[index]
	var card := MarginContainer.new()
	card.custom_minimum_size.x = PANEL_WIDTH
	var glass := UiStyle.glass_panel(Color(1, 1, 1, 0.3), 0)
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(glass)
	var button := Button.new()
	button.theme_type_variation = &"CardButton"
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_entered.connect(_preview_theme.bind(level["theme"]))
	button.focus_entered.connect(_preview_theme.bind(level["theme"]))
	button.pressed.connect(start_level.bind(index + 1))
	card.add_child(button)

	var padding := MarginContainer.new()
	padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		padding.add_theme_constant_override("margin_" + side, 18)
	for side in ["top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 11)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 1)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows := [[level["place"], &"Heading"], [level["title"], &"Title"], [level["text"], &"Muted"],
			["Victoria: " + level["goal"], &"Good"]]
	for row in rows:
		var label := _label(row[0], row[1])
		label.custom_minimum_size.x = PANEL_WIDTH - 36.0
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
	padding.add_child(content)
	card.add_child(padding)
	return card


func _build_how_screen() -> Control:
	var box := _screen()
	box.add_child(_label("Cómo jugar", &"Display", 40))
	var parts := _plaque()
	box.add_child(parts[0])
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(PANEL_WIDTH - 36.0, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_how_text = RichTextLabel.new()
	_how_text.bbcode_enabled = true
	_how_text.fit_content = true
	_how_text.scroll_active = false
	_how_text.custom_minimum_size.x = PANEL_WIDTH - 52.0
	_how_text.add_theme_font_size_override("normal_font_size", 15)
	_how_text.add_theme_font_size_override("bold_font_size", 15)
	_how_text.add_theme_constant_override("line_separation", 3)
	_how_text.text = HOW_TO_PLAY
	scroll.add_child(_how_text)
	parts[1].add_child(scroll)
	var back := _menu_button("Volver")
	back.pressed.connect(_show_screen.bind(&"main"))
	box.add_child(back)
	return box


func _build_credits_screen() -> Control:
	var box := _screen()
	box.add_child(_label("Créditos", &"Display", 40))
	box.add_child(_label("PROYECTO FINAL DE SIMULACIÓN POR COMPUTADOR · EXPOSIMU 2026", &"Heading"))
	var parts := _plaque(8)
	box.add_child(parts[0])
	for credit in CREDITS:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		row.add_child(_label("%s · %s" % [credit[0], credit[1]], &"Muted"))
		row.add_child(_label(credit[2], &"Title", 20))
		parts[1].add_child(row)
	parts[1].add_child(HSeparator.new())
	parts[1].add_child(_label("Modelos: colas M/M/1, caminata aleatoria 2D, Monte Carlo, agentes y dinámica de sistemas.", &"Muted"))
	var back := _menu_button("Volver")
	back.pressed.connect(_show_screen.bind(&"main"))
	box.add_child(back)
	return box


func _label(text: String, variation: StringName, font_size: int = 0) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Con ancho fijo desde el inicio, el salto de línea no infla la altura.
	label.custom_minimum_size.x = PANEL_WIDTH - 36.0
	if font_size > 0:
		label.add_theme_font_size_override("font_size", font_size)
	return label


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	return spacer


func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = &"BigButton"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(300, 46)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size", 19)
	return button
