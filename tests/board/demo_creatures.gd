extends RefCounted
## Fauna animada para la ambientación de la demo: aves que vuelan en
## círculo, mariposas morpho e hipopótamos en el agua.

const Meshes := preload("res://tests/board/demo_meshes.gd")


## Ave que vuela en círculos alrededor de [member center].
## kind: &"condor" (planea), &"macaw" (guacamaya, aletea rápido),
## &"vulture" (gallinazo, planea en V).
class Bird extends Node3D:
	var kind: StringName = &"condor"
	var center := Vector3.ZERO
	var radius := 9.0
	var altitude := 7.0
	var speed := 0.25
	var phase := 0.0
	var _left: Node3D
	var _right: Node3D
	var _time := 0.0

	func _ready() -> void:
		_time = phase * 10.0
		var body_color := Color("#1b1b1b")
		var wing_color := Color("#202020")
		var accent := Color("#f0ece2")
		var head_color := Color("#8a5f55")
		var span := 1.1
		var size := 1.0
		match kind:
			&"macaw":
				body_color = Color("#c8261e")
				wing_color = Color("#2b5fbf")
				accent = Color("#f2c230")
				head_color = Color("#d8d0c4")
				span = 0.45
				size = 0.45
			&"vulture":
				body_color = Color("#151515")
				wing_color = Color("#1a1a1a")
				accent = Color("#3a3a3a")
				head_color = Color("#3d3d3d")
				span = 0.7
				size = 0.6
		var body := Meshes.material(body_color, 0.7)
		Meshes.add_ellipsoid(self, Vector3.ZERO, Vector3(0.22, 0.2, 0.62) * size, body)
		Meshes.add_ellipsoid(self, Vector3(0, 0.03, -0.3) * size, Vector3(0.17, 0.15, 0.1) * size, Meshes.material(accent, 0.8))
		Meshes.add_ellipsoid(self, Vector3(0, 0.05, -0.4) * size, Vector3(0.12, 0.12, 0.16) * size, Meshes.material(head_color, 0.7))
		var tail_length := 0.5 if kind == &"macaw" else 0.25
		Meshes.add_ellipsoid(self, Vector3(0, 0, 0.3 + tail_length * 0.5) * size, Vector3(0.18, 0.03, tail_length) * size, body)
		_left = _make_wing(-1.0, span * size, wing_color, accent)
		_right = _make_wing(1.0, span * size, wing_color, accent)

	func _make_wing(side_sign: float, span: float, color: Color, accent: Color) -> Node3D:
		var pivot := Node3D.new()
		pivot.position = Vector3(side_sign * 0.09, 0.03, 0.0)
		add_child(pivot)
		var wing := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(span, 0.025, 0.34 * span / 1.1 + 0.08)
		wing.mesh = box
		wing.material_override = Meshes.material(color, 0.75)
		wing.position = Vector3(side_sign * span * 0.5, 0.0, 0.03)
		pivot.add_child(wing)
		# Banda de color sobre el ala (blanca en el cóndor, amarilla en la guacamaya).
		var band := MeshInstance3D.new()
		var band_box := BoxMesh.new()
		band_box.size = Vector3(span * 0.55, 0.03, box.size.z * 0.4)
		band.mesh = band_box
		band.material_override = Meshes.material(accent, 0.8)
		band.position = Vector3(side_sign * span * 0.35, 0.005, 0.06)
		pivot.add_child(band)
		return pivot

	func _process(delta: float) -> void:
		_time += delta
		var angle := phase * TAU + _time * speed
		var bob := sin(_time * 0.7 + phase * 5.0) * 0.4
		position = center + Vector3(cos(angle) * radius, altitude + bob, sin(angle) * radius)
		var heading := Vector3(-sin(angle), 0.0, cos(angle)) * signf(speed)
		var bank := -0.35 * signf(speed)
		basis = Basis.looking_at(heading, Vector3.UP) * Basis(Vector3.FORWARD, bank)
		var flap := 0.0
		match kind:
			&"condor":
				flap = 0.12 + sin(_time * 1.3) * 0.06
			&"macaw":
				flap = sin(_time * 14.0) * 0.6
			&"vulture":
				flap = 0.32 + sin(_time * 1.1) * 0.05
		_left.rotation.z = -flap
		_right.rotation.z = flap


## Mariposa morpho azul que revolotea alrededor del tablero.
class Butterfly extends Node3D:
	var phase := 0.0
	var radius := 7.0
	var _left: Node3D
	var _right: Node3D
	var _time := 0.0

	func _ready() -> void:
		_time = phase * 20.0
		var blue := StandardMaterial3D.new()
		blue.albedo_color = Color("#2f7dff")
		blue.emission_enabled = true
		blue.emission = Color("#2f7dff")
		blue.emission_energy_multiplier = 0.6
		blue.metallic = 0.4
		blue.roughness = 0.3
		blue.cull_mode = BaseMaterial3D.CULL_DISABLED
		var dark := Meshes.material(Color("#111111"), 0.6)
		Meshes.add_ellipsoid(self, Vector3.ZERO, Vector3(0.025, 0.025, 0.14), dark)
		for side_sign in [-1.0, 1.0]:
			var pivot := Node3D.new()
			add_child(pivot)
			var wing := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.16, 0.004, 0.14)
			wing.mesh = box
			wing.material_override = blue
			wing.position = Vector3(side_sign * 0.085, 0.0, -0.01)
			pivot.add_child(wing)
			if side_sign < 0.0:
				_left = pivot
			else:
				_right = pivot

	func _process(delta: float) -> void:
		_time += delta
		var t := _time * 0.35 + phase * TAU
		var target := Vector3(cos(t) * radius, 1.2 + sin(t * 2.3) * 0.6 + sin(_time * 3.0) * 0.08, sin(t * 1.3) * radius * 0.8)
		var heading := Vector3(target.x - position.x, 0.0, target.z - position.z)
		position = target
		if heading.length() > 0.0001:
			basis = Basis.looking_at(heading.normalized(), Vector3.UP)
		var flap := 0.2 + sin(_time * 18.0) * 0.9
		_left.rotation.z = -flap
		_right.rotation.z = flap


## Hipopótamo asomado en el agua (especie invasora del Magdalena Medio).
class Hippo extends Node3D:
	var water_level := -0.9
	var phase := 0.0
	var _time := 0.0

	func _ready() -> void:
		_time = phase * 10.0
		var skin := Meshes.material(Color("#6e5d66"), 0.6)
		var pink := Meshes.material(Color("#b98a8a"), 0.6)
		var dark := Meshes.material(Color("#141010"), 0.4)
		var white := Meshes.material(Color("#efe9e0"), 0.5)
		Meshes.add_ellipsoid(self, Vector3(0, -0.15, 0.4), Vector3(1.5, 0.9, 2.3), skin)
		Meshes.add_ellipsoid(self, Vector3(0, 0.12, -0.85), Vector3(0.95, 0.6, 0.95), skin)
		Meshes.add_ellipsoid(self, Vector3(0, 0.02, -1.3), Vector3(0.95, 0.45, 0.6), pink)
		for side_sign in [-1.0, 1.0]:
			Meshes.add_ellipsoid(self, Vector3(side_sign * 0.2, 0.22, -1.52), Vector3(0.1, 0.06, 0.08), dark)
			Meshes.add_ellipsoid(self, Vector3(side_sign * 0.26, 0.42, -0.72), Vector3(0.16, 0.14, 0.14), white)
			Meshes.add_ellipsoid(self, Vector3(side_sign * 0.27, 0.46, -0.78), Vector3(0.08, 0.08, 0.06), dark)
			Meshes.add_ellipsoid(self, Vector3(side_sign * 0.33, 0.48, -0.5), Vector3(0.12, 0.16, 0.08), skin)

	func _process(delta: float) -> void:
		_time += delta
		position.y = water_level - 0.05 + sin(_time * 0.9) * 0.06
		rotation.y += sin(_time * 0.2) * delta * 0.15
