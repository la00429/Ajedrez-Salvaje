extends SceneTree
## Pruebas del menú principal.
##
## Ejecutar desde la raíz del proyecto:
##   godot --headless --path . --script res://tests/ui/test_main_menu.gd
## Al final imprime "N comprobaciones, M fallidas".

const MENU_SCENE := preload("res://scenes/ui/MainMenu.tscn")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	var menu := MENU_SCENE.instantiate()
	root.add_child(menu)
	current_scene = menu
	process_frame.connect(_run.bind(menu), CONNECT_ONE_SHOT)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("  FALLA: " + message)


func _run(menu: Node) -> void:
	print("- Pantallas")
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/MainMenu.tscn",
			"el menú es la escena principal del proyecto")
	_check(menu._current_screen == &"main", "arranca en la pantalla de inicio")
	_check(menu._screens.size() == 4, "hay 4 pantallas: inicio, niveles, cómo jugar y créditos")
	for screen_name in [&"levels", &"how", &"credits", &"main"]:
		menu._show_screen(screen_name)
		var visible: Array = menu._screens.keys().filter(func(k): return menu._screens[k].visible)
		_check(visible == [screen_name], "solo se ve la pantalla %s" % screen_name)
	_check(menu.board.get_all_pieces().size() == 33, "el tablero de fondo tiene las 32 piezas y el cazador")
	_check(not menu.board.input_enabled, "el tablero de fondo no recibe clics")

	print("- Vista previa de biomas")
	menu._show_screen(&"levels")
	menu._preview_theme(&"santuario")
	_check(menu._theme_name == &"santuario", "pasar por un nivel cambia el bioma de fondo")

	print("- Esc vuelve al inicio")
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	menu._unhandled_input(escape)
	_check(menu._current_screen == &"main", "Esc regresa a la pantalla de inicio")

	print("- Jugar nivel 2")
	menu.start_level(2)
	await create_timer(1.6).timeout
	var game := current_scene
	_check(game != null and game.name == "BoardDemo", "se abre la escena de juego")
	_check(not is_instance_valid(menu), "el menú se libera")
	if game and game.name == "BoardDemo":
		_check(game._theme_name == &"amazonia", "el juego arranca en el bioma del nivel 2 (Amazonía)")

		print("- Volver al menú")
		game._go_to_menu()
		await process_frame
		await process_frame
		_check(current_scene != null and current_scene.name == "MainMenu", "Esc / botón vuelve al menú principal")

	print("\n%d comprobaciones, %d fallidas" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
