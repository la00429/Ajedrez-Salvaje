extends Node3D
## Ficha 3D de relleno para la demo del tablero, modelada por código.
##
## NO es la pieza real del juego: las piezas las implementa el módulo de
## piezas (scenes/pieces/ChessPiece.tscn). Estos modelos sirven para probar
## el tablero y pueden reutilizarse si el equipo lo decide.
##
## Medidas en unidades de casilla (el tablero usa casillas de 1 x 1).

const Meshes := preload("res://tests/board/demo_meshes.gd")
const NAMES := {&"pawn": "Frailejón", &"knight": "Venado", &"king": "Gran Abuelo", &"hunter": "Cazador"}

## Bando: 0 = jugador, 1 = rival, -1 = neutral (cazador).
var side := 0
## &"pawn" (frailejón), &"knight" (venado), &"king" (gran abuelo), &"hunter".
var kind: StringName = &"pawn"


func display_name() -> String:
	return NAMES.get(kind, "Ficha")


func _ready() -> void:
	match kind:
		&"pawn":
			_build_frailejon(false)
			set_meta(&"board_pick_height", 0.75)
		&"king":
			_build_frailejon(true)
			set_meta(&"board_pick_height", 1.05)
		&"knight":
			_build_deer()
			set_meta(&"board_pick_height", 1.0)
		&"hunter":
			_build_hunter()
			set_meta(&"board_pick_height", 0.9)
	# La altura de clic se expresa en casillas: se ajusta a la escala de la ficha.
	set_meta(&"board_pick_height", float(get_meta(&"board_pick_height")) * scale.y)
	# Las fichas miran hacia el bando contrario.
	if side == 1:
		rotation.y = PI


## Pedestal torneado estilo Staunton. Devuelve la altura de su cara superior.
func _build_base(top_radius: float) -> float:
	var ivory := side != 1
	var body := Meshes.material(Color("#efe6d2") if ivory else Color("#2e2724"), 0.32)
	var trim := Meshes.material(Color("#4f6b3a") if ivory else Color("#c9a046"), 0.3, 0.55)
	if side == -1:
		body = Meshes.material(Color("#3b3633"), 0.4)
		trim = Meshes.material(Color("#a3352a"), 0.35, 0.3)
	Meshes.add_lathe(self, PackedVector2Array([
		Vector2(0.35, 0.0), Vector2(0.36, 0.025), Vector2(0.35, 0.05), Vector2(0.32, 0.065),
		Vector2(0.3, 0.08), Vector2(0.31, 0.1), Vector2(0.29, 0.115), Vector2(0.22, 0.13),
		Vector2(top_radius, 0.15), Vector2(0.0, 0.151),
	]), body)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.285
	torus.outer_radius = 0.315
	torus.rings = 40
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = trim
	ring.position.y = 0.09
	add_child(ring)
	return 0.15


## Frailejón (Espeletia): tronco cubierto de hojas secas y roseta plateada.
## El Gran Abuelo es más alto, con roseta grande y corona dorada.
func _build_frailejon(grand: bool) -> void:
	var top := _build_base(0.17 if grand else 0.15)
	var height := 0.55 if grand else 0.33
	var trunk := Meshes.material(Color("#7a6650"), 0.95)
	Meshes.add_lathe(self, PackedVector2Array([
		Vector2(0.15 if grand else 0.13, top), Vector2(0.135 if grand else 0.12, top + height * 0.25),
		Vector2(0.12 if grand else 0.105, top + height * 0.7), Vector2(0.115 if grand else 0.1, top + height),
		Vector2(0.0, top + height + 0.01),
	]), trunk)
	# Anillos de hojas secas sobre el tronco.
	var dry := Meshes.material(Color("#5e4c3a"), 1.0)
	for i in 3:
		var y := top + height * (0.3 + i * 0.25)
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.08 if grand else 0.07
		torus.outer_radius = 0.14 if grand else 0.125
		torus.rings = 24
		torus.ring_segments = 6
		ring.mesh = torus
		ring.material_override = dry
		ring.position.y = y
		ring.scale.y = 0.6
		add_child(ring)

	var player := side != 1
	var outer := Meshes.material(Color("#a9b98f") if player else Color("#86a072"), 0.85)
	var inner := Meshes.material(Color("#d3dcba") if player else Color("#b4c69a"), 0.8)
	var crown_y := top + height
	Meshes.add_rosette(self, Vector3(0, crown_y, 0), 0.34 if grand else 0.27, 15 if grand else 11, outer, inner)

	if grand:
		_build_crown(crown_y + 0.12)
	else:
		# Inflorescencias amarillas sobre tallos finos.
		var stalk := Meshes.material(Color("#7d8c55"), 0.8)
		var flower := Meshes.material(Color("#f2c94c"), 0.5)
		for i in 3:
			var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 3.0 + 0.4)
			var tip := Vector3(0, crown_y + 0.2, 0) + direction * 0.07
			Meshes.add_segment(self, Vector3(0, crown_y, 0), tip, 0.008, stalk)
			Meshes.add_ellipsoid(self, tip, Vector3(0.06, 0.06, 0.06), flower)


func _build_crown(y: float) -> void:
	var gold := Meshes.material(Color("#e0b24a"), 0.25, 0.85)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.085
	torus.outer_radius = 0.12
	torus.rings = 32
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = gold
	ring.position.y = y
	add_child(ring)
	var gem := Meshes.material(Color("#e8f2c8"), 0.15, 0.2)
	for i in 5:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 5.0)
		var base := Vector3(0, y, 0) + direction * 0.1
		Meshes.add_segment(self, base, base + Vector3(0, 0.1, 0) + direction * 0.015, 0.024, gold, 0.004)
		Meshes.add_ellipsoid(self, base + Vector3(0, 0.11, 0) + direction * 0.016, Vector3(0.03, 0.03, 0.03), gem)


## Venado de cola blanca: cuello torneado, cabeza, orejas y astas ramificadas.
func _build_deer() -> void:
	var top := _build_base(0.17)
	var fur := Meshes.material(Color("#a2714a"), 0.9)
	var light := Meshes.material(Color("#e7d6bd"), 0.9)
	var dark := Meshes.material(Color("#1c140e"), 0.3)
	var antler := Meshes.material(Color("#e8dcc0"), 0.55)
	Meshes.add_lathe(self, PackedVector2Array([
		Vector2(0.17, top), Vector2(0.155, top + 0.08), Vector2(0.13, top + 0.2), Vector2(0.115, top + 0.3),
		Vector2(0.0, top + 0.31),
	]), fur)
	var head := Vector3(0, top + 0.4, -0.02)
	Meshes.add_ellipsoid(self, head, Vector3(0.21, 0.21, 0.25), fur)
	# Hocico apuntando al frente (-Z) y un poco hacia abajo.
	var snout_basis := Basis(Vector3.RIGHT, deg_to_rad(18.0))
	Meshes.add_ellipsoid(self, head + Vector3(0, -0.05, -0.14), Vector3(0.13, 0.12, 0.22), fur, snout_basis)
	Meshes.add_ellipsoid(self, head + Vector3(0, -0.085, -0.21), Vector3(0.1, 0.07, 0.1), light, snout_basis)
	Meshes.add_ellipsoid(self, head + Vector3(0, -0.07, -0.255), Vector3(0.055, 0.04, 0.04), dark)
	Meshes.add_ellipsoid(self, head + Vector3(0, -0.14, -0.06), Vector3(0.12, 0.08, 0.1), light) # garganta blanca
	for s in [-1.0, 1.0]:
		Meshes.add_ellipsoid(self, head + Vector3(s * 0.075, 0.025, -0.095), Vector3(0.035, 0.035, 0.03), dark)
		var ear_basis := Basis(Vector3.FORWARD, s * deg_to_rad(-55.0)) * Basis(Vector3.RIGHT, deg_to_rad(-15.0))
		Meshes.add_ellipsoid(self, head + Vector3(s * 0.13, 0.06, 0.02), Vector3(0.06, 0.02, 0.14) * Vector3(1, 1, 1), fur,
				Basis(Vector3.UP, s * deg_to_rad(70.0)) * ear_basis)
		var root := head + Vector3(s * 0.06, 0.085, 0.02)
		var p1 := head + Vector3(s * 0.13, 0.21, 0.05)
		var p2 := head + Vector3(s * 0.21, 0.31, 0.0)
		var p3 := head + Vector3(s * 0.25, 0.39, -0.07)
		Meshes.add_segment(self, root, p1, 0.017, antler)
		Meshes.add_segment(self, p1, p2, 0.015, antler)
		Meshes.add_segment(self, p2, p3, 0.012, antler, 0.006)
		Meshes.add_segment(self, p1, head + Vector3(s * 0.1, 0.33, -0.04), 0.012, antler, 0.005)
		Meshes.add_segment(self, p2, head + Vector3(s * 0.19, 0.43, 0.04), 0.011, antler, 0.005)


## Cazador furtivo: figura con chaqueta, sombrero de ala ancha y fusil.
func _build_hunter() -> void:
	var top := _build_base(0.16)
	var pants := Meshes.material(Color("#3d3a2c"), 0.9)
	var jacket := Meshes.material(Color("#8e2b20"), 0.8)
	var skin := Meshes.material(Color("#d9a77a"), 0.7)
	var hat := Meshes.material(Color("#4a4a2e"), 0.85)
	var metal := Meshes.material(Color("#2a2826"), 0.35, 0.7)
	var wood := Meshes.material(Color("#6b4a2e"), 0.7)
	for s in [-1.0, 1.0]:
		Meshes.add_segment(self, Vector3(s * 0.05, top, 0), Vector3(s * 0.05, top + 0.2, 0), 0.04, pants)
		Meshes.add_segment(self, Vector3(s * 0.12, top + 0.42, 0), Vector3(s * 0.15, top + 0.24, -0.03), 0.033, jacket)
	var torso := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.11
	capsule.height = 0.34
	torso.mesh = capsule
	torso.material_override = jacket
	torso.position.y = top + 0.32
	add_child(torso)
	Meshes.add_ellipsoid(self, Vector3(0, top + 0.53, 0), Vector3(0.15, 0.16, 0.15), skin)
	Meshes.add_segment(self, Vector3(0, top + 0.575, 0), Vector3(0, top + 0.585, 0), 0.14, hat)
	Meshes.add_segment(self, Vector3(0, top + 0.58, 0), Vector3(0, top + 0.66, 0), 0.075, hat, 0.06)
	Meshes.add_segment(self, Vector3(0.11, top + 0.12, 0.08), Vector3(-0.13, top + 0.68, 0.08), 0.014, metal)
	Meshes.add_segment(self, Vector3(0.11, top + 0.12, 0.08), Vector3(0.15, top + 0.04, 0.085), 0.028, wood)
