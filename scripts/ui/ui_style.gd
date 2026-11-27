extends RefCounted
## Estilo visual compartido por el menú principal y el HUD: vidrio esmerilado.
##
## Los paneles desenfocan la escena que tienen detrás (ver
## scenes/ui/glass.gdshader), la oscurecen un poco para que el texto se lea y
## tienen un borde blanco fino. El texto es blanco, en tipografía sans, con
## encabezados en mayúsculas espaciadas. El color del bioma ([BoardTheme])
## solo se usa como acento: botones activos, barras y resultados.
##
## Uso:
## - [code]control.theme = UiStyle.build(board_theme)[/code] en la raíz de la
##   interfaz; al cambiar de bioma, [code]UiStyle.apply(control.theme, tema)[/code].
## - Paneles de vidrio: [code]UiStyle.glass_panel()[/code].
##
## Variaciones de tipo (theme_type_variation):
## - PanelContainer: "Chip"
## - Label: "Heading", "Title", "Display", "Muted", "Good"
## - Button: "BigButton", "CardButton" (transparente, para tarjetas)

const GLASS_SHADER := preload("res://scenes/ui/glass.gdshader")

const TEXT := Color("#f6f4ee")
const ALERT := Color("#ff7a62")
const WATER := Color("#6cc6ff")
const GOOD := Color("#c9f0a6")
const DARK_TEXT := Color("#16181a")
const RADIUS := 10

static var _materials := {}
static var _bold: FontVariation
static var _spaced: FontVariation


## Material de vidrio compartido. [param border] colorea el borde (por
## ejemplo, rojo para avisos de jaque).
static func glass_material(border: Color = Color(1, 1, 1, 0.38)) -> ShaderMaterial:
	var key := border.to_html()
	if not _materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = GLASS_SHADER
		material.set_shader_parameter(&"border_color", border)
		_materials[key] = material
	return _materials[key]


## Panel de vidrio esmerilado listo para usar (con márgenes internos).
static func glass_panel(border: Color = Color(1, 1, 1, 0.38), margin: int = 14) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.material = glass_material(border)
	panel.add_theme_stylebox_override("panel", glass_mask(margin))
	return panel


## Caja que sirve de máscara al shader: fondo negro (forma) y borde blanco.
static func glass_mask(margin: int = 14, radius: int = RADIUS) -> StyleBoxFlat:
	var mask := box(Color.BLACK, radius, 1, Color.WHITE, margin)
	mask.anti_aliasing = true
	return mask


static func bold_font() -> Font:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.7
	return _bold


static func spaced_font() -> Font:
	if _spaced == null:
		_spaced = FontVariation.new()
		_spaced.base_font = ThemeDB.fallback_font
		_spaced.spacing_glyph = 2
		_spaced.variation_embolden = 0.5
	return _spaced


## Color de acento del bioma, aclarado para que resalte sobre el vidrio.
static func accent(t: BoardTheme) -> Color:
	return t.frame_accent_color.lightened(0.25)


static func text(_t: BoardTheme = null) -> Color:
	return TEXT


static func build(t: BoardTheme) -> Theme:
	var theme := Theme.new()
	apply(theme, t)
	return theme


## Ajusta el tema a los colores de acento de [param t].
static func apply(theme: Theme, t: BoardTheme) -> void:
	var a := accent(t)
	theme.default_font_size = 14

	theme.set_stylebox("panel", "PanelContainer", glass_mask())
	theme.set_type_variation("Chip", "PanelContainer")
	var chip := box(Color(1, 1, 1, 0.12), 6, 1, Color(1, 1, 1, 0.22), 7)
	chip.content_margin_top = 2
	chip.content_margin_bottom = 2
	theme.set_stylebox("panel", "Chip", chip)

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.35))
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_type_variation("Heading", "Label")
	theme.set_font("font", "Heading", spaced_font())
	theme.set_font_size("font_size", "Heading", 11)
	theme.set_color("font_color", "Heading", Color(TEXT, 0.68))
	theme.set_type_variation("Title", "Label")
	theme.set_font("font", "Title", bold_font())
	theme.set_font_size("font_size", "Title", 21)
	theme.set_type_variation("Display", "Label")
	theme.set_font("font", "Display", bold_font())
	theme.set_font_size("font_size", "Display", 36)
	theme.set_type_variation("Muted", "Label")
	theme.set_color("font_color", "Muted", Color(TEXT, 0.62))
	theme.set_font_size("font_size", "Muted", 12)
	theme.set_type_variation("Good", "Label")
	theme.set_color("font_color", "Good", GOOD)
	theme.set_font_size("font_size", "Good", 13)

	# Botones translúcidos: se aclaran al pasar el cursor; activos con el acento.
	var normal := box(Color(1, 1, 1, 0.1), 8, 1, Color(1, 1, 1, 0.22), 12)
	var hover := box(Color(1, 1, 1, 0.2), 8, 1, Color(1, 1, 1, 0.6), 12)
	var pressed := box(Color(a, 0.92), 8, 1, a.lightened(0.3), 12)
	var hover_pressed := box(a.lightened(0.1), 8, 1, a.lightened(0.4), 12)
	var focus := box(Color(0, 0, 0, 0), 8, 1, Color(1, 1, 1, 0.75), 12)
	focus.draw_center = false
	for button_type in ["Button", "BigButton"]:
		theme.set_stylebox("normal", button_type, normal)
		theme.set_stylebox("hover", button_type, hover)
		theme.set_stylebox("pressed", button_type, pressed)
		theme.set_stylebox("hover_pressed", button_type, hover_pressed)
		theme.set_stylebox("focus", button_type, focus)
		theme.set_color("font_color", button_type, TEXT)
		theme.set_color("font_hover_color", button_type, Color.WHITE)
		theme.set_color("font_focus_color", button_type, Color.WHITE)
		theme.set_color("font_pressed_color", button_type, DARK_TEXT)
		theme.set_color("font_hover_pressed_color", button_type, DARK_TEXT)
	theme.set_font_size("font_size", "Button", 13)
	theme.set_type_variation("BigButton", "Button")
	theme.set_font_size("font_size", "BigButton", 16)
	theme.set_font("font", "BigButton", bold_font())

	# Botón transparente que va encima de una tarjeta de vidrio.
	theme.set_type_variation("CardButton", "Button")
	theme.set_stylebox("normal", "CardButton", StyleBoxEmpty.new())
	theme.set_stylebox("hover", "CardButton", box(Color(1, 1, 1, 0.08), RADIUS, 1, Color(1, 1, 1, 0.7), 0))
	theme.set_stylebox("pressed", "CardButton", box(Color(1, 1, 1, 0.14), RADIUS, 1, Color.WHITE, 0))
	var card_focus := box(Color(0, 0, 0, 0), RADIUS, 1, Color(1, 1, 1, 0.8), 0)
	card_focus.draw_center = false
	theme.set_stylebox("focus", "CardButton", card_focus)

	var line := StyleBoxLine.new()
	line.color = Color(1, 1, 1, 0.16)
	line.thickness = 1
	theme.set_stylebox("separator", "HSeparator", line)
	var grabber := box(Color(1, 1, 1, 0.35), 2, 0, Color.TRANSPARENT, 0)
	grabber.content_margin_left = 2
	grabber.content_margin_right = 2
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber)
	theme.set_stylebox("scroll", "VScrollBar", box(Color(1, 1, 1, 0.06), 2, 0, Color.TRANSPARENT, 0))


## Tema mínimo, sin recuadros, para el HUD de la partida: texto directo sobre
## la escena con contorno y sombra suaves, botones de texto que se subrayan
## con el acento del bioma, y botones de ícono discretos.
##
## Variaciones: Label "Heading", "Title", "Display", "Muted", "Good";
## Button "BigButton" (texto grande) e "IconButton".
static func build_minimal(t: BoardTheme) -> Theme:
	var theme := Theme.new()
	apply_minimal(theme, t)
	return theme


static func apply_minimal(theme: Theme, t: BoardTheme) -> void:
	var a := accent(t)
	theme.default_font_size = 14
	for type in ["Label", "Button"]:
		theme.set_color("font_outline_color", type, Color(0, 0, 0, 0.55))
		theme.set_constant("outline_size", type, 4)
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.45))
	theme.set_constant("shadow_offset_x", "Label", 0)
	theme.set_constant("shadow_offset_y", "Label", 2)
	theme.set_type_variation("Heading", "Label")
	theme.set_font("font", "Heading", spaced_font())
	theme.set_font_size("font_size", "Heading", 11)
	theme.set_color("font_color", "Heading", Color(TEXT, 0.78))
	theme.set_type_variation("Title", "Label")
	theme.set_font("font", "Title", bold_font())
	theme.set_font_size("font_size", "Title", 18)
	theme.set_type_variation("Display", "Label")
	theme.set_font("font", "Display", bold_font())
	theme.set_font_size("font_size", "Display", 52)
	theme.set_constant("outline_size", "Display", 8)
	theme.set_type_variation("Muted", "Label")
	theme.set_color("font_color", "Muted", Color(TEXT, 0.7))
	theme.set_font_size("font_size", "Muted", 13)
	theme.set_type_variation("Good", "Label")
	theme.set_color("font_color", "Good", GOOD)
	theme.set_font_size("font_size", "Good", 14)

	# Botones de texto: sin fondo; subrayado con el acento al pasar o enfocar.
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 6
	empty.content_margin_right = 6
	empty.content_margin_top = 3
	empty.content_margin_bottom = 5
	var underline := StyleBoxFlat.new()
	underline.draw_center = false
	underline.border_width_bottom = 2
	underline.border_color = a
	underline.content_margin_left = 6
	underline.content_margin_right = 6
	underline.content_margin_top = 3
	underline.content_margin_bottom = 5
	for button_type in ["Button", "BigButton"]:
		theme.set_stylebox("normal", button_type, empty)
		theme.set_stylebox("pressed", button_type, underline)
		theme.set_stylebox("hover", button_type, underline)
		theme.set_stylebox("hover_pressed", button_type, underline)
		theme.set_stylebox("focus", button_type, underline)
		theme.set_color("font_color", button_type, Color(TEXT, 0.82))
		theme.set_color("font_hover_color", button_type, Color.WHITE)
		theme.set_color("font_focus_color", button_type, Color.WHITE)
		theme.set_color("font_pressed_color", button_type, a)
		theme.set_color("font_hover_pressed_color", button_type, a.lightened(0.2))
	theme.set_font("font", "Button", bold_font())
	theme.set_font_size("font_size", "Button", 14)
	theme.set_type_variation("BigButton", "Button")
	theme.set_font_size("font_size", "BigButton", 22)

	theme.set_type_variation("IconButton", "Button")
	var round := box(Color(1, 1, 1, 0.14), 18, 0, Color.TRANSPARENT, 0)
	for state in ["normal", "pressed", "focus"]:
		theme.set_stylebox(state, "IconButton", StyleBoxEmpty.new())
	theme.set_stylebox("hover", "IconButton", round)
	theme.set_stylebox("hover_pressed", "IconButton", round)

	var grabber := box(Color(1, 1, 1, 0.35), 2, 0, Color.TRANSPARENT, 0)
	grabber.content_margin_left = 2
	grabber.content_margin_right = 2
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber)
	theme.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())


static func box(bg: Color, radius: int, border: int, border_color: Color, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border)
	style.border_color = border_color
	style.set_content_margin_all(margin)
	return style
