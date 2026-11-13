extends SceneTree
## Pruebas del módulo de tablero (Integrante 1).
##
## Ejecutar desde la raíz del proyecto:
##   godot --headless --path . --script res://tests/board/test_board.gd
## Termina con código 0 si todo pasa y 1 si alguna prueba falla.

const BOARD_SCENE := preload("res://scenes/board/Board.tscn")

var _failures := 0
var _checks := 0
var _board: Board
var _tokens: Array[Node3D] = []


func _initialize() -> void:
	_board = BOARD_SCENE.instantiate()
	_board.animations_enabled = false
	_board.play_intro_on_ready = false

	_section("Uso antes de entrar a la escena")
	var early := _token()
	_check(_board.place_piece(early, Vector2i(3, 3)), "se puede colocar una pieza recién instanciado el tablero")
	_check(_board.destroy_piece(Vector2i(3, 3)), "y retirarla")

	root.add_child(_board)
	process_frame.connect(_run_all, CONNECT_ONE_SHOT)


func _run_all() -> void:
	_test_structure()
	_test_coordinates()
	_test_world_conversion()
	_test_ray_picking()
	_test_place_move_remove()
	_test_capture_flow()
	_test_row_queries()
	_test_neighborhoods()
	_test_blocked_and_highlights()
	_test_signals()
	_test_initial_setup_from_spec()
	_test_themes()
	await _test_animations()

	print("\n%d comprobaciones, %d fallidas" % [_checks, _failures])
	# Libera las fichas de prueba que quedaron fuera del tablero.
	for token in _tokens:
		if is_instance_valid(token) and not token.is_inside_tree() and not token.is_queued_for_deletion():
			token.free()
	await process_frame
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("  FALLA: " + message)


func _section(title: String) -> void:
	print("- " + title)


func _token() -> Node3D:
	var token := Node3D.new()
	_tokens.append(token)
	return token


func _test_structure() -> void:
	_section("Estructura 8x8")
	_check(_board.get_node("Cells").get_child_count() == 64, "debe haber 64 casillas")
	_check(_board.get_cell(Vector2i(0, 0)) is Cell, "a1 debe ser un Cell")
	_check(_board.get_cell(Vector2i(8, 0)) == null, "i1 no existe")
	_check(not Board.is_light_square(Vector2i(0, 0)), "a1 es oscura")
	_check(Board.is_light_square(Vector2i(7, 0)), "h1 es clara")
	_check(not Board.is_light_square(Vector2i(7, 7)), "h8 es oscura")
	_check(Board.is_light_square(Vector2i(3, 0)), "d1 es clara (dama en su color)")
	_check(not _board.get_cell(Vector2i(0, 0)).is_light, "la casilla a1 se construye oscura")
	_check(_board.get_cell(Vector2i(7, 0)).is_light, "la casilla h1 se construye clara")
	_check(_board.get_cell(Vector2i(0, 0)).tile.material_override != _board.get_cell(Vector2i(7, 0)).tile.material_override,
			"claras y oscuras usan materiales distintos")
	_check(_board.get_cell(Vector2i(0, 0)).tile.material_override == _board.get_cell(Vector2i(2, 0)).tile.material_override,
			"las oscuras comparten material")
	_check(_board.get_cell(Vector2i(0, 0)).position == _board.coord_to_position(Vector2i(0, 0)), "el origen de la casilla es el centro de su cara superior")
	_check(_board.get_node("Effects") != null, "existe la capa de efectos")
	_check(_board.get_node("Frame").get_child_count() > 0, "el marco está construido")
	var labels := _board.get_node("Frame").get_children().filter(func(n): return n is Label3D)
	_check(labels.size() == 32, "32 coordenadas en el marco (8 letras y 8 números, en ambos lados)")


func _test_coordinates() -> void:
	_section("Coordenadas y notación algebraica")
	_check(Board.coord_to_algebraic(Vector2i(4, 3)) == "e4", "(4,3) -> e4")
	_check(Board.coord_to_algebraic(Vector2i(0, 0)) == "a1", "(0,0) -> a1")
	_check(Board.coord_to_algebraic(Vector2i(7, 7)) == "h8", "(7,7) -> h8")
	_check(Board.coord_to_algebraic(Vector2i(8, 0)) == "", "fuera del tablero -> \"\"")
	_check(Board.algebraic_to_coord("e4") == Vector2i(4, 3), "e4 -> (4,3)")
	_check(Board.algebraic_to_coord("H8") == Vector2i(7, 7), "H8 en mayúscula -> (7,7)")
	_check(Board.algebraic_to_coord("i1") == Board.INVALID, "i1 inválida")
	_check(Board.algebraic_to_coord("a9") == Board.INVALID, "a9 inválida")
	_check(Board.algebraic_to_coord("a0") == Board.INVALID, "a0 inválida")
	_check(Board.algebraic_to_coord("e") == Board.INVALID, "texto corto inválido")
	_check(Board.algebraic_to_coord("ex") == Board.INVALID, "fila no numérica inválida")
	for x in Board.SIZE:
		for y in Board.SIZE:
			var c := Vector2i(x, y)
			if Board.algebraic_to_coord(Board.coord_to_algebraic(c)) != c:
				_check(false, "ida y vuelta falla en %s" % c)
	_check(Board.is_inside(Vector2i(0, 0)) and Board.is_inside(Vector2i(7, 7)), "esquinas dentro")
	_check(not Board.is_inside(Vector2i(-1, 0)) and not Board.is_inside(Vector2i(0, 8)), "bordes fuera")


func _test_world_conversion() -> void:
	_section("Mundo 3D <-> casillas")
	var s := _board.cell_size
	_check(_board.coord_to_position(Vector2i(0, 0)) == Vector3(-3.5 * s, 0, 3.5 * s), "a1: izquierda (-X), lado del jugador (+Z)")
	_check(_board.coord_to_position(Vector2i(7, 7)) == Vector3(3.5 * s, 0, -3.5 * s), "h8: derecha (+X), lado rival (-Z)")
	for x in Board.SIZE:
		for y in Board.SIZE:
			var c := Vector2i(x, y)
			if _board.position_to_coord(_board.coord_to_position(c)) != c:
				_check(false, "centro de %s no vuelve a la misma casilla" % c)
			if _board.position_to_coord(_board.coord_to_position(c) + Vector3(0.45, 2.0, -0.45) * s) != c:
				_check(false, "un punto dentro de %s (a cualquier altura) cae en la misma casilla" % c)
	_check(_board.position_to_coord(Vector3(-4.1, 0, 0) * s) == Board.INVALID, "a la izquierda del tablero: fuera")
	_check(_board.position_to_coord(Vector3(0, 0, 4.01) * s) == Board.INVALID, "delante del tablero: fuera")
	_check(_board.get_board_size() == 8 * s, "lado del tablero")
	var bounds := _board.get_bounds()
	_check(bounds.size.x > 8 * s and bounds.position.y < 0.0, "la caja incluye marco y base")


func _test_ray_picking() -> void:
	_section("Clic con rayo desde la cámara")
	var e4 := Vector2i(4, 3)
	var e3 := Vector2i(4, 2)
	var e5 := Vector2i(4, 4)
	var e4_floor := _board.to_global(_board.coord_to_position(e4))
	_check(_board.ray_to_coord(e4_floor + Vector3.UP * 10.0, Vector3.DOWN) == e4, "rayo vertical sobre e4")
	var camera := Vector3(e4_floor.x, 10.0, 10.0)
	_check(_board.ray_to_coord(camera, (e4_floor - camera).normalized()) == e4, "rayo oblicuo hacia e4 (vacío delante)")
	_check(_board.ray_to_coord(camera, Vector3.UP) == Board.INVALID, "rayo hacia arriba: nada")
	_check(_board.ray_to_coord(Vector3(50, 10, 0), Vector3.DOWN) == Board.INVALID, "rayo fuera del tablero")

	var blocker := _token()
	_board.place_piece(blocker, e3)
	_check(_board.ray_to_coord(camera, (e4_floor - camera).normalized()) == e3,
			"si una pieza en e3 tapa la vista de e4, el clic la selecciona a ella")
	_board.destroy_piece(e3, false)

	var tall := _token()
	_board.place_piece(tall, e4)
	var head := e4_floor + Vector3.UP * 0.9 * _board.cell_size
	var through_head := (head - camera).normalized()
	_board.remove_piece(e4, false)
	_check(_board.ray_to_coord(camera, through_head) == e5, "sin pieza, ese rayo llega al suelo en e5")
	_board.place_piece(tall, e4)
	_check(_board.ray_to_coord(camera, through_head) == e4, "con pieza, clic en su cabeza selecciona e4")
	tall.set_meta(Board.PICK_HEIGHT_META, 0.3)
	_check(_board.ray_to_coord(camera, through_head) == e5, "una pieza baja (pick height 0.3) no tapa")
	_board.clear_pieces()


func _test_place_move_remove() -> void:
	_section("Colocar, mover y retirar")
	var e2 := Vector2i(4, 1)
	var e4 := Vector2i(4, 3)
	var pawn := _token()
	_check(_board.place_piece(pawn, e2), "colocar en e2")
	_check(_board.get_piece_at(e2) == pawn, "e2 ocupada por el peón")
	_check(pawn.get_parent() == _board.get_node("Pieces"), "el peón queda bajo Pieces")
	_check(pawn.position == _board.coord_to_position(e2), "el peón queda centrado en e2")
	_check(_board.is_occupied(e2) and not _board.is_empty(e2), "e2 ocupada")
	_check(not _board.place_piece(_token(), e2), "no se puede colocar sobre una casilla ocupada")
	_check(not _board.place_piece(pawn, e4), "la misma pieza no se coloca dos veces")
	_check(not _board.place_piece(_token(), Vector2i(9, 9)), "no se coloca fuera del tablero")
	_check(_board.find_piece(pawn) == e2, "find_piece encuentra e2")

	_check(_board.move_piece(e2, e4), "mover e2 -> e4")
	_check(_board.is_empty(e2) and _board.get_piece_at(e4) == pawn, "e2 vacía y e4 ocupada")
	_check(pawn.position == _board.coord_to_position(e4), "posición visual actualizada")
	_check(not _board.move_piece(e2, e4), "no se mueve desde una casilla vacía")
	_check(not _board.move_piece(e4, e4), "no se mueve a la misma casilla")
	_check(not _board.move_piece(e4, Vector2i(4, 8)), "no se mueve fuera del tablero")

	var removed := _board.remove_piece(e4)
	_check(removed == pawn, "remove_piece devuelve el peón")
	_check(not pawn.is_inside_tree(), "el peón retirado sale del árbol")
	_check(is_instance_valid(pawn), "remove_piece no libera el nodo")
	_check(_board.remove_piece(e4) == null, "retirar de casilla vacía devuelve null")
	_check(_board.find_piece(pawn) == Board.INVALID, "la pieza retirada ya no se encuentra")
	_check(_board.place_piece(pawn, Vector2i(0, 1)), "una pieza retirada se puede volver a colocar (vivero)")
	_check(_board.destroy_piece(Vector2i(0, 1)), "destroy_piece en a2")
	_check(not _board.destroy_piece(Vector2i(0, 1)), "destroy_piece en casilla vacía devuelve false")
	_check(_board.get_occupied_coords().is_empty(), "tablero vacío al final")


func _test_capture_flow() -> void:
	_section("Captura en dos pasos")
	var attacker := _token()
	var victim := _token()
	var f3 := Vector2i(5, 2)
	var e5 := Vector2i(4, 4)
	_board.place_piece(attacker, f3)
	_board.place_piece(victim, e5)
	_check(not _board.move_piece(f3, e5), "move_piece no captura implícitamente")
	var captured := _board.remove_piece(e5)
	_check(captured == victim, "se retira la víctima")
	_check(_board.move_piece(f3, e5), "luego se mueve el atacante")
	_check(_board.get_piece_at(e5) == attacker, "el atacante ocupa e5")
	captured.free()
	_board.clear_pieces()
	_check(_board.get_all_pieces().is_empty(), "clear_pieces vacía el tablero")


func _test_row_queries() -> void:
	_section("Consultas por fila (vivero)")
	_check(_board.first_empty_in_row(1) == Vector2i(0, 1), "fila 2 vacía: primera libre es a2")
	_board.place_piece(_token(), Vector2i(0, 1))
	_board.place_piece(_token(), Vector2i(1, 1))
	_check(_board.first_empty_in_row(1) == Vector2i(2, 1), "con a2 y b2 ocupadas: c2")
	_check(_board.get_empty_coords_in_row(1).size() == 6, "quedan 6 libres en la fila 2")
	for x in Board.SIZE:
		_board.place_piece(_token(), Vector2i(x, 1))
	_check(_board.first_empty_in_row(1) == Board.INVALID, "fila llena -> INVALID")
	_check(_board.get_empty_coords().size() == 56, "56 casillas vacías en total")
	_board.clear_pieces()


func _test_neighborhoods() -> void:
	_section("Vecindades y distancias")
	_check(Board.get_moore_neighborhood(Vector2i(3, 3), 1).size() == 8, "Moore r=1 en el centro: 8")
	_check(Board.get_moore_neighborhood(Vector2i(3, 3), 2).size() == 24, "Moore r=2 en el centro: 24")
	_check(Board.get_moore_neighborhood(Vector2i(0, 0), 2).size() == 8, "Moore r=2 en a1: 8")
	_check(not Board.get_moore_neighborhood(Vector2i(3, 3), 2).has(Vector2i(3, 3)), "Moore no incluye el centro")
	_check(Board.get_orthogonal_neighbors(Vector2i(3, 3)).size() == 4, "4 vecinos ortogonales en d4")
	_check(Board.get_orthogonal_neighbors(Vector2i(0, 0)).size() == 2, "2 vecinos ortogonales en a1")
	_check(Board.manhattan_distance(Vector2i(0, 0), Vector2i(3, 4)) == 7, "Manhattan a1-d5 = 7")
	_check(Board.chebyshev_distance(Vector2i(0, 0), Vector2i(3, 4)) == 4, "Chebyshev a1-d5 = 4")
	# Caminata del documento: d4 -O-> c4 -N-> c5 -E-> d5 -E-> e5
	var hunter := Board.algebraic_to_coord("d4")
	for step in [Board.WEST, Board.NORTH, Board.EAST, Board.EAST]:
		hunter += step
	_check(Board.coord_to_algebraic(hunter) == "e5", "caminata del ejemplo termina en e5")


func _test_blocked_and_highlights() -> void:
	_section("Bloqueos y resaltados")
	var c4 := Vector2i(2, 3)
	_board.set_blocked(c4)
	_check(_board.is_blocked(c4), "c4 bloqueada")
	_check(_board.get_blocked_coords() == [c4], "lista de bloqueadas")
	_check(not _board.is_blocked(Vector2i(20, 20)), "fuera del tablero no está bloqueada")
	_board.clear_blocked()
	_check(_board.get_blocked_coords().is_empty(), "clear_blocked")

	_board.highlight_cells([Vector2i(0, 2), Vector2i(0, 3), Vector2i(99, 0)], Cell.Highlight.MOVE)
	_check(_board.get_highlight(Vector2i(0, 3)) == Cell.Highlight.MOVE, "a4 resaltada como MOVE")
	_board.set_highlight(Vector2i(4, 0), Cell.Highlight.CHECK)
	_check(_board.get_highlight(Vector2i(4, 0)) == Cell.Highlight.CHECK, "e1 en jaque")
	_board.clear_highlights()
	_check(_board.get_highlight(Vector2i(0, 3)) == Cell.Highlight.NONE, "clear_highlights")

	var original_theme := _board.board_theme
	_board.apply_palette(Color.WHITE, Color.BLACK)
	var dark_material: ShaderMaterial = _board.get_cell(Vector2i(0, 0)).tile.material_override
	_check(dark_material.get_shader_parameter(&"base_color") == Color.BLACK, "apply_palette cambia el material oscuro")
	_check(_board.board_theme.light_color == Color.WHITE, "apply_palette cambia el color claro")
	_check(original_theme.dark_color != Color.BLACK, "apply_palette no modifica el tema original")
	_board.cell_size = 2.0
	_check(_board.get_cell(Vector2i(1, 0)).position == Vector3(-5, 0, 7), "cambiar cell_size reubica casillas")
	_board.cell_size = 1.0
	var custom := StandardMaterial3D.new()
	_board.get_cell(Vector2i(2, 2)).custom_material = custom
	_board.board_theme = _board.board_theme
	_check(_board.get_cell(Vector2i(2, 2)).tile.material_override == custom, "un material propio sobrevive al cambio de tema")
	_board.get_cell(Vector2i(2, 2)).custom_material = null


func _test_signals() -> void:
	_section("Señales")
	var events: Array[String] = []
	_board.piece_placed.connect(func(_p, c): events.append("placed " + Board.coord_to_algebraic(c)))
	_board.piece_moved.connect(func(_p, a, b): events.append("moved %s-%s" % [Board.coord_to_algebraic(a), Board.coord_to_algebraic(b)]))
	_board.piece_removed.connect(func(_p, c): events.append("removed " + Board.coord_to_algebraic(c)))
	_board.cell_blocked_changed.connect(func(c, b): events.append("blocked %s %s" % [Board.coord_to_algebraic(c), b]))
	_board.place_piece(_token(), Vector2i(6, 0))
	_board.move_piece(Vector2i(6, 0), Vector2i(5, 2))
	_board.destroy_piece(Vector2i(5, 2))
	_board.set_blocked(Vector2i(0, 0))
	_board.set_blocked(Vector2i(0, 0)) # repetido: no emite
	_board.set_blocked(Vector2i(0, 0), false)
	_check(events == ["placed g1", "moved g1-f3", "removed f3", "blocked a1 true", "blocked a1 false"],
			"orden de señales: %s" % [events])

	var clicked: Array[Vector2i] = []
	_board.cell_clicked.connect(func(c): clicked.append(c))
	_board.cell_clicked.emit(Vector2i(1, 1))
	_check(clicked == [Vector2i(1, 1)], "cell_clicked llega a los oyentes")


func _test_initial_setup_from_spec() -> void:
	_section("Disposición inicial del documento (sección 4.2)")
	_board.clear_pieces()
	var squares := ["a2", "b2", "c2", "d2", "e2", "f2", "g2", "h2", "b1", "g1", "e1",
			"a7", "b7", "c7", "d7", "e7", "f7", "g7", "h7", "b8", "g8", "e8", "d4"]
	for square in squares:
		_check(_board.place_piece(_token(), Board.algebraic_to_coord(square)), "colocar en " + square)
	_check(_board.get_all_pieces().size() == 23, "8+2+1 por bando y el cazador = 23")
	_check(Board.coord_to_algebraic(_board.first_empty_in_row(0)) == "a1", "primera libre de la fila 1 es a1")
	_board.clear_pieces()


func _test_themes() -> void:
	_section("Temas y marco")
	for preset in BoardTheme.PRESETS:
		var t := BoardTheme.create(preset)
		_check(t.light_color != t.dark_color, "tema %s: casillas distinguibles" % preset)
		_check(t.light_color.get_luminance() > t.dark_color.get_luminance(), "tema %s: la clara es más clara" % preset)
	_board.board_theme = BoardTheme.create(&"amazonia")
	var dark_material: ShaderMaterial = _board.get_cell(Vector2i(0, 0)).tile.material_override
	_check(dark_material.get_shader_parameter(&"base_color") == BoardTheme.create(&"amazonia").dark_color, "cambiar tema recolorea")
	_board.board_theme = null
	_check(_board.board_theme != null, "tema null vuelve al tema por defecto")
	var frame := _board.get_frame_width()
	_check(frame > 0.0, "el tema por defecto tiene marco")
	var half := _board.get_board_size() * 0.5 + frame
	_check(is_equal_approx(_board.get_bounds().size.x, half * 2.0), "la caja mide tablero + 2 marcos")
	var labels := _board.get_node("Frame").get_children().filter(func(n): return n is Label3D)
	_check(labels.size() == 32, "reconstruir el marco no duplica coordenadas")
	_board.show_coordinates = false
	labels = _board.get_node("Frame").get_children().filter(func(n): return n is Label3D)
	_check(labels.is_empty(), "show_coordinates = false quita las coordenadas")
	_board.show_coordinates = true


func _test_animations() -> void:
	_section("Animaciones (con tiempo real)")
	_board.animations_enabled = true
	_board.play_intro()
	_check(_board.get_cell(Vector2i(7, 7)).position.y < 0.0, "la intro empieza con las casillas hundidas")
	var knight := _token()
	knight.scale = Vector3(0.5, 0.5, 0.5)
	_board.place_piece(knight, Vector2i(6, 0))
	_check(knight.scale.length() < 0.01, "durante la intro la pieza espera para caer")
	_check(knight.position.y > 0.0, "la pieza cae desde arriba")
	await create_timer(2.2).timeout
	_check(is_zero_approx(_board.get_cell(Vector2i(7, 7)).position.y), "al terminar la intro las casillas están en su lugar")
	_check(_board.get_cell(Vector2i(7, 7)).scale.is_equal_approx(Vector3.ONE), "y con escala 1")
	_check(knight.scale.is_equal_approx(Vector3(0.5, 0.5, 0.5)), "la pieza termina con su escala original")
	_check(knight.position.is_equal_approx(_board.coord_to_position(Vector2i(6, 0))), "la pieza aterriza en g1")

	_board.move_piece(Vector2i(6, 0), Vector2i(5, 2))
	await create_timer(0.15).timeout
	_check(knight.position.y > 0.1, "el salto sube por el aire")
	await create_timer(0.8).timeout
	_check(knight.position.is_equal_approx(_board.coord_to_position(Vector2i(5, 2))), "el salto termina en f3")
	_check(knight.scale.is_equal_approx(Vector3(0.5, 0.5, 0.5)), "tras el salto conserva su escala")

	# Mover dos veces seguidas: la segunda animación reemplaza a la primera.
	_board.move_piece(Vector2i(5, 2), Vector2i(4, 4))
	_board.move_piece(Vector2i(4, 4), Vector2i(3, 2))
	await create_timer(1.0).timeout
	_check(knight.position.is_equal_approx(_board.coord_to_position(Vector2i(3, 2))), "movimientos encadenados terminan en d3")

	_board.destroy_piece(Vector2i(3, 2))
	_check(_board.get_node("Effects").get_child_count() == 1, "retirar una pieza muestra polvo")
	_board.set_blocked(Vector2i(0, 0))
	_check(_board.get_node("Effects").get_child_count() == 2, "bloquear una casilla muestra chispas")
	_board.remove_piece(Vector2i(0, 0), false)
	await create_timer(1.4).timeout
	_check(_board.get_node("Effects").get_child_count() == 0, "los efectos se liberan solos")
	_board.clear_blocked()
	_board.animations_enabled = false
