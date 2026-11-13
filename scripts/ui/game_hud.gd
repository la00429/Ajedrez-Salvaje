class_name GameHUD
extends Control
## Interfaz de la partida (HUD) de Ajedrez Salvaje, sin recuadros.
##
## El texto va directo sobre la escena, con sombra y contorno suaves y un
## degradado leve arriba y abajo para que se lea:
## - Nivel: aparece grande al empezar ([method play_level_intro]) y luego se
##   encoge a una línea arriba a la izquierda. El objetivo se muestra unos
##   segundos y al pasar el mouse por esa línea.
## - Turno: un punto y "Tu turno" en el borde superior del tablero
##   ([method set_turn_anchor]).
## - Ecosistema: íconos pequeños de agua, clima y vivero. Lo pendiente no se
##   muestra.
## - Jugadas: cajón a la derecha, cerrado por defecto (Tab o ícono).
## - Íconos discretos arriba a la derecha: jugadas, vista y pausa.
## - Menú de pruebas (F1): paso del cazador, catástrofe, rival automático.
## - Pausa (Esc) y fin de partida a pantalla completa, sin cajas.
##
## Solo presenta información: no calcula nada. El juego le pasa los datos con
## los métodos [code]set_*[/code] y escucha sus señales.

signal hunter_step_requested
signal catastrophe_requested
signal view_toggle_requested
signal restart_requested
signal menu_requested
signal auto_rival_toggled(enabled: bool)
signal theme_selected(theme_name: StringName)
signal pause_changed(paused: bool)

const UiStyle := preload("res://scripts/ui/ui_style.gd")
const HudIcon := preload("res://scripts/ui/hud_icon.gd")

const PLAYER := 0
const RIVAL := 1
const DRAWER_WIDTH := 250.0
const THEMES := [[&"paramo", "Páramo"], [&"amazonia", "Amazonía"], [&"santuario", "Santuario"], [&"clasico", "Clásico"]]

var _board_theme := BoardTheme.new()
var _level_line: Control
var _level_tag: Label
var _level_title: Label
var _level_goal: Label
var _goal_tween: Tween
var _intro: VBoxContainer
var _intro_tag: Label
var _intro_title: Label
var _intro_place: Label
var _intro_goal: Label
var _turn_row: HBoxContainer
var _turn_dot: HudIcon
var _turn_label: Label
var _in_check := false
var _eco_row: HBoxContainer
var _water_item: HBoxContainer
var _water_fill: Panel
var _water_value: Label
var _climate_item: HBoxContainer
var _climate_icon: HudIcon
var _climate_value: Label
var _nursery_item: HBoxContainer
var _nursery_value: Label
var _drawer: Control
var _drawer_open := false
var _drawer_tween: Tween
var _moves_grid: GridContainer
var _moves_scroll: ScrollContainer
var _hover_label: Label
var _banner: Label
var _banner_tween: Tween
var _debug_panel: VBoxContainer
var _auto_button: Button
var _pause_layer: Control
var _game_over_layer: Control
var _game_over_box: VBoxContainer
var _game_over_title: Label
var _game_over_subtitle: Label
var _game_over_result: StringName = &"draw"
var _theme_buttons := {}
var _move_count := 0
var _paused := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiStyle.build_minimal(_board_theme)
	_build_gradients()
	_build_level()
	_build_turn()
	_build_corner()
	_build_drawer()
	_build_hover_and_banner()
	_build_debug_panel()
	_build_pause_menu()
	_build_game_over()
	set_ecosystem()
	_refresh_dynamic_styles()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _game_over_layer.visible:
		set_paused(not _paused)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and not _paused:
		if event.keycode == KEY_TAB:
			toggle_moves()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F1:
			toggle_debug()
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# API para el juego
# ---------------------------------------------------------------------------

## Ajusta el color de acento al bioma.
func apply_board_theme(board_theme: BoardTheme) -> void:
	_board_theme = board_theme
	if theme:
		UiStyle.apply_minimal(theme, board_theme)
		_refresh_dynamic_styles()


func set_level(number: int, title: String, place: String, objective: String) -> void:
	var tag := ("NIVEL %d" % number) if number > 0 else "PARTIDA LIBRE"
	_level_tag.text = tag + "  ·"
	_level_title.text = title
	_level_goal.text = objective
	_intro_tag.text = tag
	_intro_title.text = title
	_intro_place.text = place
	_intro_goal.text = objective
	_intro_goal.visible = objective != ""


## Muestra el nombre del nivel en grande y luego lo encoge a la línea de
## arriba a la izquierda. El objetivo queda visible unos segundos.
func play_level_intro(delay: float = 0.6) -> void:
	_level_line.modulate.a = 0.0
	_intro.visible = true
	_intro.modulate.a = 0.0
	_intro.scale = Vector2(1.06, 1.06)
	await get_tree().process_frame
	_intro.pivot_offset = _intro.size * 0.5
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(_intro, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(_intro, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.8)
	# Al escalar desde el centro, la esquina superior izquierda queda en
	# position + pivot * (1 - escala): se lleva justo a la línea del nivel.
	var target := _level_line.position - _intro.pivot_offset * 0.7
	tween.tween_property(_intro, "position", target, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_intro, "scale", Vector2(0.3, 0.3), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_intro, "modulate:a", 0.0, 0.6)
	tween.parallel().tween_property(_level_line, "modulate:a", 1.0, 0.5).set_delay(0.3)
	tween.tween_callback(_finish_intro)


func _finish_intro() -> void:
	_intro.visible = false
	_intro.position = Vector2.ZERO
	_intro.scale = Vector2.ONE
	_intro.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_show_goal(4.0)


## Turno actual. [param side]: 0 jugador, 1 rival.
func set_turn(side: int, _move_number: int, in_check: bool) -> void:
	var player := side == PLAYER
	_in_check = in_check
	_turn_label.text = ("¡Jaque! " if in_check else "") + ("Tu turno" if player else "Turno del rival")
	_turn_dot.color = UiStyle.ALERT if in_check else (Color("#f4eedf") if player else Color("#2e2724"))
	_refresh_dynamic_styles()


## Ubica el indicador de turno sobre el borde superior del tablero (posición
## en pantalla). [param visible_on_screen] = false lo oculta.
func set_turn_anchor(screen_position: Vector2, visible_on_screen: bool = true) -> void:
	_turn_row.visible = visible_on_screen
	if visible_on_screen:
		_turn_row.position = (screen_position - Vector2(_turn_row.size.x * 0.5, _turn_row.size.y + 6.0)).round()


## Reemplaza el texto del turno (por ejemplo, "Jaque mate" al terminar).
func set_turn_message(text: String) -> void:
	_turn_label.text = text


## Indicadores del ecosistema. Los valores pendientes (NAN, "" o -1) no se
## muestran. [param climate]: "Estable", "Lluvia", "Helada" o "Catástrofe".
func set_ecosystem(water_percent: float = NAN, climate: String = "", nursery_queue: int = -1) -> void:
	_water_item.visible = not is_nan(water_percent)
	if _water_item.visible:
		_water_value.text = "%d%%" % roundi(water_percent)
		_water_fill.anchor_right = clampf(water_percent / 100.0, 0.0, 1.0)
		_water_fill.modulate = Color.WHITE if water_percent > 30.0 else UiStyle.ALERT
	_climate_item.visible = climate != ""
	if _climate_item.visible:
		_climate_value.text = climate
		var lower := climate.to_lower()
		_climate_icon.kind = &"rain" if lower.begins_with("lluv") else (&"frost" if lower.begins_with("hel") else (&"fire" if lower.begins_with("cat") else &"sun"))
	_nursery_item.visible = nursery_queue >= 0
	if _nursery_item.visible:
		_nursery_value.text = str(nursery_queue)


func clear_moves() -> void:
	for child in _moves_grid.get_children():
		child.queue_free()
	_move_count = 0


## Agrega una jugada al historial del cajón (en notación algebraica).
func add_move(side: int, notation: String) -> void:
	if _move_count % 2 == 0:
		_add_move_cell("%d." % (_move_count / 2 + 1), true)
		if side == RIVAL:
			_add_move_cell("…", true)
			_move_count += 1
	_add_move_cell(notation, false, side == RIVAL)
	_move_count += 1
	await get_tree().process_frame
	_moves_scroll.scroll_vertical = int(_moves_scroll.get_v_scroll_bar().max_value)


## Abre o cierra el cajón de jugadas.
func toggle_moves() -> void:
	_drawer_open = not _drawer_open
	if _drawer_tween and _drawer_tween.is_valid():
		_drawer_tween.kill()
	_drawer_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_drawer_tween.tween_property(_drawer, "offset_left", -DRAWER_WIDTH if _drawer_open else 0.0, 0.3)


## Muestra u oculta el menú de pruebas (F1).
func toggle_debug() -> void:
	_debug_panel.visible = not _debug_panel.visible


## Texto de la casilla bajo el cursor ("" lo oculta).
func set_hover_info(text: String) -> void:
	_hover_label.text = text
	_hover_label.visible = text != ""


## Aviso temporal arriba al centro. [param kind]: &"info", &"alert" o &"gold".
func show_banner(text: String, kind: StringName = &"info") -> void:
	_banner.text = text
	var accent := UiStyle.accent(_board_theme)
	_banner.add_theme_color_override("font_color", UiStyle.ALERT.lightened(0.2) if kind == &"alert" else (accent if kind == &"gold" else UiStyle.TEXT))
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner.visible = true
	_banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_interval(1.8)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.5)


## Pantalla de fin de partida. [param result]: &"victory", &"defeat" o &"draw".
func show_game_over(title: String, subtitle: String, result: StringName) -> void:
	_game_over_title.text = title
	_game_over_subtitle.text = subtitle
	_game_over_result = result
	_refresh_dynamic_styles()
	_game_over_layer.visible = true
	_game_over_layer.modulate.a = 0.0
	create_tween().tween_property(_game_over_layer, "modulate:a", 1.0, 0.4)


func hide_game_over() -> void:
	_game_over_layer.visible = false


func set_auto_rival(enabled: bool) -> void:
	_auto_button.set_pressed_no_signal(enabled)
	_auto_button.text = "Rival automático: %s" % ("sí" if enabled else "no")


func set_theme_name(theme_name: StringName) -> void:
	for key in _theme_buttons:
		_theme_buttons[key].set_pressed_no_signal(key == theme_name)


func is_paused() -> bool:
	return _paused


func set_paused(paused: bool) -> void:
	_paused = paused
	_pause_layer.visible = paused
	if paused:
		_pause_layer.modulate.a = 0.0
		create_tween().tween_property(_pause_layer, "modulate:a", 1.0, 0.2)
		var first := _pause_layer.find_child("Continuar", true, false) as Button
		if first:
			first.grab_focus()
	pause_changed.emit(paused)


# ---------------------------------------------------------------------------
# Construcción
# ---------------------------------------------------------------------------

## Degradados muy leves arriba y abajo para que el texto se lea sobre la escena.
func _build_gradients() -> void:
	for top in [true, false]:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(0, 0, 0, 0.42 if top else 0.0))
		gradient.set_color(1, Color(0, 0, 0, 0.0 if top else 0.4))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill_from = Vector2(0, 0)
		texture.fill_to = Vector2(0, 1)
		texture.width = 4
		texture.height = 64
		var rect := TextureRect.new()
		rect.texture = texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.anchor_right = 1.0
		if top:
			rect.offset_bottom = 130
		else:
			rect.anchor_top = 1.0
			rect.anchor_bottom = 1.0
			rect.offset_top = -120
		add_child(rect)


func _build_level() -> void:
	_level_line = VBoxContainer.new()
	_level_line.position = Vector2(24, 18)
	_level_line.add_theme_constant_override("separation", 2)
	_level_line.mouse_filter = Control.MOUSE_FILTER_PASS
	_level_line.mouse_entered.connect(_show_goal.bind(0.0))
	_level_line.mouse_exited.connect(_hide_goal)
	add_child(_level_line)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	_level_line.add_child(row)
	_level_tag = _label("NIVEL 1  ·", &"Heading")
	_level_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_level_tag)
	_level_title = _label("", &"Title")
	row.add_child(_level_title)
	_level_goal = _label("", &"Good")
	_level_goal.custom_minimum_size.x = 300
	_level_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_level_goal.modulate.a = 0.0
	_level_line.add_child(_level_goal)

	_intro = VBoxContainer.new()
	_intro.alignment = BoxContainer.ALIGNMENT_CENTER
	_intro.add_theme_constant_override("separation", 4)
	_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro.visible = false
	add_child(_intro)
	_intro_tag = _label("", &"Heading", true)
	_intro_tag.add_theme_font_size_override("font_size", 15)
	_intro_title = _label("", &"Display", true)
	_intro_place = _label("", &"Muted", true)
	_intro_place.add_theme_font_size_override("font_size", 17)
	_intro_goal = _label("", &"Good", true)
	_intro_goal.add_theme_font_size_override("font_size", 16)
	for label in [_intro_tag, _intro_title, _intro_place, _intro_goal]:
		_intro.add_child(label)
	_intro.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_intro.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_intro.grow_vertical = Control.GROW_DIRECTION_BOTH


func _show_goal(seconds: float) -> void:
	if _goal_tween and _goal_tween.is_valid():
		_goal_tween.kill()
	_goal_tween = create_tween()
	_goal_tween.tween_property(_level_goal, "modulate:a", 1.0, 0.25)
	if seconds > 0.0:
		_goal_tween.tween_interval(seconds)
		_goal_tween.tween_property(_level_goal, "modulate:a", 0.0, 0.6)


func _hide_goal() -> void:
	if _goal_tween and _goal_tween.is_valid():
		_goal_tween.kill()
	_goal_tween = create_tween()
	_goal_tween.tween_property(_level_goal, "modulate:a", 0.0, 0.4)


func _build_turn() -> void:
	_turn_row = HBoxContainer.new()
	_turn_row.add_theme_constant_override("separation", 8)
	_turn_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_turn_row)
	_turn_dot = HudIcon.new()
	_turn_dot.custom_minimum_size = Vector2(14, 14)
	_turn_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_turn_row.add_child(_turn_dot)
	_turn_label = _label("Tu turno", &"Title")
	_turn_row.add_child(_turn_label)


## Arriba a la derecha: íconos (jugadas, vista, pausa) y debajo el ecosistema.
func _build_corner() -> void:
	var column := VBoxContainer.new()
	column.anchor_left = 1.0
	column.anchor_right = 1.0
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.offset_right = -18
	column.offset_top = 14
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var icons := HBoxContainer.new()
	icons.alignment = BoxContainer.ALIGNMENT_END
	icons.add_theme_constant_override("separation", 4)
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icons)
	icons.add_child(_icon_button(&"list", "Jugadas (Tab)", toggle_moves))
	icons.add_child(_icon_button(&"view", "Vista panorámica (V)", func() -> void: view_toggle_requested.emit()))
	icons.add_child(_icon_button(&"pause", "Pausa (Esc)", set_paused.bind(true)))

	_eco_row = HBoxContainer.new()
	_eco_row.alignment = BoxContainer.ALIGNMENT_END
	_eco_row.add_theme_constant_override("separation", 16)
	_eco_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_eco_row)
	# Agua: gota + barra delgada + porcentaje.
	_water_item = _eco_item(&"drop", UiStyle.WATER)
	var bar := Panel.new()
	bar.custom_minimum_size = Vector2(72, 5)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("panel", UiStyle.box(Color(1, 1, 1, 0.22), 3, 0, Color.TRANSPARENT, 0))
	_water_fill = Panel.new()
	_water_fill.anchor_bottom = 1.0
	_water_fill.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.WATER, 3, 0, Color.TRANSPARENT, 0))
	bar.add_child(_water_fill)
	_water_item.add_child(bar)
	_water_value = _label("", &"Title")
	_water_value.add_theme_font_size_override("font_size", 14)
	_water_item.add_child(_water_value)
	_eco_row.add_child(_water_item)
	# Clima: ícono + nombre corto.
	_climate_item = _eco_item(&"sun", Color("#ffe08a"))
	_climate_icon = _climate_item.get_child(0) as HudIcon
	_climate_value = _label("", &"Title")
	_climate_value.add_theme_font_size_override("font_size", 14)
	_climate_item.add_child(_climate_value)
	_eco_row.add_child(_climate_item)
	# Vivero: brote + número en cola.
	_nursery_item = _eco_item(&"sprout", UiStyle.GOOD)
	_nursery_value = _label("", &"Title")
	_nursery_value.add_theme_font_size_override("font_size", 14)
	_nursery_item.add_child(_nursery_value)
	_nursery_item.tooltip_text = "Plantas en el vivero"
	_eco_row.add_child(_nursery_item)


func _eco_item(icon_kind: StringName, icon_color: Color) -> HBoxContainer:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", 6)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := HudIcon.new()
	icon.kind = icon_kind
	icon.color = icon_color
	icon.custom_minimum_size = Vector2(16, 16)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item.add_child(icon)
	return item


func _icon_button(icon_kind: StringName, tip: String, action: Callable) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"IconButton"
	button.custom_minimum_size = Vector2(36, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = tip
	button.pressed.connect(action)
	var icon := HudIcon.new()
	icon.kind = icon_kind
	icon.color = Color(UiStyle.TEXT, 0.85)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.custom_minimum_size = Vector2(18, 18)
	icon.position = Vector2(9, 9)
	button.add_child(icon)
	return button


## Cajón de jugadas a la derecha: un degradado oscuro (sin borde) que entra
## desde el costado.
func _build_drawer() -> void:
	_drawer = Control.new()
	_drawer.anchor_left = 1.0
	_drawer.anchor_right = 1.0
	_drawer.anchor_bottom = 1.0
	_drawer.offset_left = 0.0
	_drawer.offset_right = DRAWER_WIDTH
	_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_drawer)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0.0))
	gradient.set_color(1, Color(0, 0, 0, 0.62))
	gradient.add_point(0.3, Color(0, 0, 0, 0.5))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 4
	var shade := TextureRect.new()
	shade.texture = texture
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drawer.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 46
	box.offset_top = 110
	box.offset_right = -18
	box.offset_bottom = -90
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drawer.add_child(box)
	box.add_child(_label("JUGADAS", &"Heading"))
	_moves_scroll = ScrollContainer.new()
	_moves_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_moves_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_moves_scroll)
	_moves_grid = GridContainer.new()
	_moves_grid.columns = 3
	_moves_grid.add_theme_constant_override("h_separation", 14)
	_moves_grid.add_theme_constant_override("v_separation", 3)
	_moves_scroll.add_child(_moves_grid)


func _add_move_cell(text: String, is_number: bool, rival: bool = false) -> void:
	var cell := _label(text, &"Muted" if is_number else &"Title")
	if not is_number:
		cell.add_theme_font_size_override("font_size", 15)
	cell.custom_minimum_size.x = 26 if is_number else 70
	if rival:
		cell.add_theme_color_override("font_color", Color(UiStyle.TEXT, 0.72))
	_moves_grid.add_child(cell)


func _build_hover_and_banner() -> void:
	_hover_label = _label("", &"Muted")
	_hover_label.add_theme_font_size_override("font_size", 14)
	_hover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hover_label.anchor_left = 0.5
	_hover_label.anchor_right = 0.5
	_hover_label.anchor_top = 1.0
	_hover_label.anchor_bottom = 1.0
	_hover_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hover_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hover_label.offset_bottom = -22
	_hover_label.visible = false
	add_child(_hover_label)

	_banner = _label("", &"Title")
	_banner.add_theme_font_size_override("font_size", 26)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.offset_top = 64
	_banner.visible = false
	add_child(_banner)

	var hint := _label("Esc pausa  ·  Tab jugadas  ·  F1 pruebas", &"Muted")
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate.a = 0.7
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_right = -20
	hint.offset_bottom = -20
	add_child(hint)


## Menú de pruebas (F1): acciones para probar la simulación, ocultas al jugador.
func _build_debug_panel() -> void:
	_debug_panel = VBoxContainer.new()
	_debug_panel.anchor_top = 1.0
	_debug_panel.anchor_bottom = 1.0
	_debug_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_debug_panel.offset_left = 20
	_debug_panel.offset_bottom = -20
	_debug_panel.add_theme_constant_override("separation", 0)
	_debug_panel.visible = false
	add_child(_debug_panel)
	_debug_panel.add_child(_label("PRUEBAS  ·  F1", &"Heading"))
	for entry in [["Paso del cazador   (Espacio)", hunter_step_requested], ["Catástrofe   (C)", catastrophe_requested],
			["Reiniciar partida   (R)", restart_requested]]:
		var button := _text_button(entry[0])
		var action: Signal = entry[1]
		button.pressed.connect(func() -> void: action.emit())
		_debug_panel.add_child(button)
	_auto_button = _text_button("Rival automático: sí")
	_auto_button.toggle_mode = true
	_auto_button.button_pressed = true
	_auto_button.tooltip_text = "Rival PROVISIONAL (la IA real es del módulo de simulación). Apagado: mueves ambos bandos."
	_auto_button.toggled.connect(_on_auto_toggled)
	_debug_panel.add_child(_auto_button)


func _on_auto_toggled(enabled: bool) -> void:
	_auto_button.text = "Rival automático: %s" % ("sí" if enabled else "no")
	auto_rival_toggled.emit(enabled)


func _build_pause_menu() -> void:
	_pause_layer = _overlay()
	var box := _centered_box()
	_pause_layer.add_child(box)
	box.add_child(_centered_label("Pausa", &"Display"))
	box.add_child(_spacer(10))
	var resume := _big_button("Continuar")
	resume.name = "Continuar"
	resume.pressed.connect(set_paused.bind(false))
	box.add_child(resume)
	box.add_child(_spacer(6))
	box.add_child(_centered_label("BIOMA", &"Heading"))
	var themes := HBoxContainer.new()
	themes.alignment = BoxContainer.ALIGNMENT_CENTER
	themes.add_theme_constant_override("separation", 10)
	var group := ButtonGroup.new()
	for entry in THEMES:
		var button := _text_button(entry[1])
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_ALL
		var theme_name: StringName = entry[0]
		button.pressed.connect(func() -> void: theme_selected.emit(theme_name))
		themes.add_child(button)
		_theme_buttons[theme_name] = button
	box.add_child(themes)
	box.add_child(_spacer(6))
	var restart := _big_button("Reiniciar partida")
	restart.pressed.connect(_on_restart_pressed)
	box.add_child(restart)
	var menu := _big_button("Menú principal")
	menu.pressed.connect(func() -> void: menu_requested.emit())
	box.add_child(menu)


func _build_game_over() -> void:
	_game_over_layer = _overlay()
	_game_over_box = _centered_box()
	_game_over_layer.add_child(_game_over_box)
	_game_over_title = _centered_label("", &"Display")
	_game_over_title.add_theme_font_size_override("font_size", 64)
	_game_over_box.add_child(_game_over_title)
	_game_over_subtitle = _centered_label("", &"Muted")
	_game_over_subtitle.add_theme_font_size_override("font_size", 17)
	_game_over_box.add_child(_game_over_subtitle)
	_game_over_box.add_child(_spacer(16))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 36)
	var again := _big_button("Revancha")
	again.pressed.connect(_on_restart_pressed)
	row.add_child(again)
	var menu := _big_button("Menú principal")
	menu.pressed.connect(func() -> void: menu_requested.emit())
	row.add_child(menu)
	_game_over_box.add_child(row)


func _on_restart_pressed() -> void:
	hide_game_over()
	if _paused:
		set_paused(false)
	restart_requested.emit()


func _refresh_dynamic_styles() -> void:
	if _turn_label == null or _game_over_title == null:
		return
	var accent := UiStyle.accent(_board_theme)
	_turn_label.add_theme_color_override("font_color", UiStyle.ALERT.lightened(0.25) if _in_check else UiStyle.TEXT)
	var result_color := accent if _game_over_result == &"victory" else (UiStyle.ALERT.lightened(0.15) if _game_over_result == &"defeat" else UiStyle.TEXT)
	_game_over_title.add_theme_color_override("font_color", result_color)


# ---------------------------------------------------------------------------
# Piezas
# ---------------------------------------------------------------------------

func _overlay() -> Control:
	var layer := ColorRect.new()
	layer.color = Color(0, 0, 0, 0.62)
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.visible = false
	add_child(layer)
	return layer


func _centered_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 6)
	return box


func _centered_label(text: String, variation: StringName) -> Label:
	var label := _label(text, variation)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _label(text: String, variation: StringName = &"", _center: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _center:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _text_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button


func _big_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = &"BigButton"
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return button
