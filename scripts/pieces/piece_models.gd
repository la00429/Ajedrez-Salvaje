extends RefCounted
## Modelos 3D de las piezas de Ajedrez Salvaje, construidos por código.
##
## Todas comparten un pedestal torneado estilo Staunton (marfil para el
## jugador, ébano para el rival) y encima la figura de su especie:
##
## - Peón: frailejón (Espeletia grandiflora)
## - Caballo: venado de cola blanca
## - Alfil: cóndor andino
## - Torre: oso de anteojos asomado en una torre almenada
## - Dama: danta (tapir) de montaña con tiara
## - Rey: frailejón Gran Abuelo con corona
## - Cazador furtivo (ocupante neutral)
##
## Medidas en unidades de casilla (casilla = 1). La figura mira hacia -Z.

const Kit := preload("res://scripts/pieces/mesh_kit.gd")

const PAWN := 1
const KNIGHT := 2
const BISHOP := 3
const ROOK := 4
const QUEEN := 5
const KING := 6
const HUNTER := 16

const PLAYER := 0
const RIVAL := 1
const NEUTRAL := -1


## Construye la figura dentro de [param root]. Devuelve su altura (en
## casillas) para la detección de clics.
static func build(root: Node3D, kind: int, side: int) -> float:
	match kind:
		PAWN:
			_frailejon(root, side)
			return 0.75
		KING:
			_grand_frailejon(root, side)
			return 1.2
		KNIGHT:
			_deer(root, side)
			return 1.0
		BISHOP:
			_condor(root, side)
			return 0.9
		ROOK:
			_bear_tower(root, side)
			return 0.85
		QUEEN:
			_tapir(root, side)
			return 0.95
		_:
			_hunter(root)
			return 0.9


## Pedestal torneado. Devuelve la altura de su cara superior. El rey usa
## ribete dorado ([param royal]) para distinguirse a primera vista.
static func _base(root: Node3D, side: int, top_radius: float, royal: bool = false) -> float:
	var body := _side_material(side)
	var trim := Kit.material(Color("#4f6b3a") if side != RIVAL else Color("#c9a046"), 0.3, 0.55)
	if side == NEUTRAL:
		trim = Kit.material(Color("#a3352a"), 0.35, 0.3)
	if royal:
		trim = _gold()
	Kit.add_lathe(root, PackedVector2Array([
		Vector2(0.35, 0.0), Vector2(0.36, 0.025), Vector2(0.35, 0.05), Vector2(0.32, 0.065),
		Vector2(0.3, 0.08), Vector2(0.31, 0.1), Vector2(0.29, 0.115), Vector2(0.22, 0.13),
		Vector2(top_radius, 0.15), Vector2(0.0, 0.151),
	]), body)
	Kit.add_torus(root, 0.09, 0.285, 0.315, trim)
	return 0.15


## Marfil (jugador), ébano (rival) o acero oscuro (neutral).
static func _side_material(side: int) -> StandardMaterial3D:
	match side:
		RIVAL:
			return Kit.material(Color("#2e2724"), 0.32)
		NEUTRAL:
			return Kit.material(Color("#3b3633"), 0.4)
	return Kit.material(Color("#efe6d2"), 0.32)


static func _gold() -> StandardMaterial3D:
	return Kit.material(Color("#e0b24a"), 0.25, 0.85)


## Frailejón joven (peón): tronco corto, roseta verde plateada y tres
## flores amarillas.
static func _frailejon(root: Node3D, side: int) -> void:
	var top := _base(root, side, 0.15)
	var height := 0.33
	Kit.add_lathe(root, PackedVector2Array([
		Vector2(0.13, top), Vector2(0.12, top + height * 0.25), Vector2(0.105, top + height * 0.7),
		Vector2(0.1, top + height), Vector2(0.0, top + height + 0.01),
	]), Kit.material(Color("#7a6650"), 0.95))
	var dry := Kit.material(Color("#5e4c3a"), 1.0)
	for i in 3:
		Kit.add_torus(root, top + height * (0.3 + i * 0.25), 0.07, 0.125, dry, 0.6)
	var player := side != RIVAL
	var outer := Kit.material(Color("#a9b98f") if player else Color("#86a072"), 0.85)
	var inner := Kit.material(Color("#d3dcba") if player else Color("#b4c69a"), 0.8)
	var crown_y := top + height
	Kit.add_rosette(root, Vector3(0, crown_y, 0), 0.27, 11, outer, inner)
	var stalk := Kit.material(Color("#7d8c55"), 0.8)
	var flower := Kit.material(Color("#f2c94c"), 0.5)
	for i in 3:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 3.0 + 0.4)
		var tip := Vector3(0, crown_y + 0.2, 0) + direction * 0.07
		Kit.add_segment(root, Vector3(0, crown_y, 0), tip, 0.008, stalk)
		Kit.add_ellipsoid(root, tip, Vector3(0.06, 0.06, 0.06), flower)


## Frailejón Gran Abuelo (rey): un frailejón centenario, mucho más alto que
## los peones, con la "falda" de hojas secas colgando del tronco, roseta
## plateada y lanuda, aro dorado y una gran corona con cojín rojo, orbe y
## cruz. Es la pieza más alta del tablero.
static func _grand_frailejon(root: Node3D, side: int) -> void:
	var top := _base(root, side, 0.18, true)
	var height := 0.6
	var player := side != RIVAL
	Kit.add_lathe(root, PackedVector2Array([
		Vector2(0.15, top), Vector2(0.14, top + 0.1), Vector2(0.125, top + 0.4), Vector2(0.12, top + height),
		Vector2(0.0, top + height + 0.01),
	]), Kit.material(Color("#6e5b47"), 0.95))
	# Falda de hojas secas colgantes en tres pisos.
	var dry := Kit.material(Color("#7a6248"), 1.0)
	var dry_dark := Kit.material(Color("#5a4634"), 1.0)
	for level in 3:
		var y := top + 0.2 + level * 0.15
		var count := 14
		for i in count:
			var angle := TAU * (i + level * 0.5) / count
			# Arrancan en la superficie del tronco y cuelgan abiertas hacia afuera.
			Kit.add_leaf(root, Vector3(0, y, 0) + Vector3.BACK.rotated(Vector3.UP, angle) * 0.12, angle, deg_to_rad(-58.0),
					0.19, 0.07, dry if (i + level) % 2 == 0 else dry_dark)
	Kit.add_torus(root, top + height * 0.97, 0.115, 0.15, _gold(), 0.6)
	var crown_y := top + height
	var outer := Kit.material(Color("#c9d1bd") if player else Color("#9fb08c"), 0.9)
	var inner := Kit.material(Color("#eef0e4") if player else Color("#c4ceb4"), 0.85)
	Kit.add_rosette(root, Vector3(0, crown_y, 0), 0.32, 16, outer, inner)
	_royal_crown(root, crown_y + 0.15)


## Corona del rey: aro dorado alto con puntas y gemas, cojín de terciopelo
## rojo, y orbe con cruz encima.
static func _royal_crown(root: Node3D, y: float) -> void:
	var gold := _gold()
	var velvet := Kit.material(Color("#9b1d20"), 0.6)
	Kit.add_lathe(root, PackedVector2Array([
		Vector2(0.11, y - 0.03), Vector2(0.125, y + 0.04), Vector2(0.115, y + 0.05), Vector2(0.0, y + 0.051),
	]), gold)
	Kit.add_ellipsoid(root, Vector3(0, y + 0.07, 0), Vector3(0.2, 0.12, 0.2), velvet)
	_crown(root, y + 0.04, 0.12, 6, 0.09)
	Kit.add_ellipsoid(root, Vector3(0, y + 0.16, 0), Vector3.ONE * 0.065, gold)
	Kit.add_segment(root, Vector3(0, y + 0.18, 0), Vector3(0, y + 0.29, 0), 0.014, gold)
	Kit.add_segment(root, Vector3(-0.04, y + 0.25, 0), Vector3(0.04, y + 0.25, 0), 0.013, gold)


## Corona o tiara dorada con puntas y gemas.
static func _crown(root: Node3D, y: float, radius: float, points: int, spike: float, center: Vector3 = Vector3.ZERO) -> void:
	var gold := _gold()
	var ring := Kit.add_torus(root, y, radius * 0.85, radius * 1.2, gold)
	ring.position.x = center.x
	ring.position.z = center.z
	var gem := Kit.material(Color("#e8f2c8"), 0.15, 0.2)
	for i in points:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / points)
		var base := center + Vector3(0, y, 0) + direction * radius
		Kit.add_segment(root, base, base + Vector3(0, spike, 0) + direction * spike * 0.15, radius * 0.24, gold, radius * 0.04)
		Kit.add_ellipsoid(root, base + Vector3(0, spike * 1.1, 0) + direction * spike * 0.16, Vector3.ONE * radius * 0.3, gem)


## Venado de cola blanca: cuello torneado, cabeza, orejas y astas ramificadas.
static func _deer(root: Node3D, side: int) -> void:
	var top := _base(root, side, 0.17)
	var fur := Kit.material(Color("#a2714a"), 0.9)
	var light := Kit.material(Color("#e7d6bd"), 0.9)
	var dark := Kit.material(Color("#1c140e"), 0.3)
	var antler := Kit.material(Color("#e8dcc0"), 0.55)
	Kit.add_lathe(root, PackedVector2Array([
		Vector2(0.17, top), Vector2(0.155, top + 0.08), Vector2(0.13, top + 0.2), Vector2(0.115, top + 0.3),
		Vector2(0.0, top + 0.31),
	]), fur)
	var head := Vector3(0, top + 0.4, -0.02)
	Kit.add_ellipsoid(root, head, Vector3(0.21, 0.21, 0.25), fur)
	var snout_basis := Basis(Vector3.RIGHT, deg_to_rad(18.0))
	Kit.add_ellipsoid(root, head + Vector3(0, -0.05, -0.14), Vector3(0.13, 0.12, 0.22), fur, snout_basis)
	Kit.add_ellipsoid(root, head + Vector3(0, -0.085, -0.21), Vector3(0.1, 0.07, 0.1), light, snout_basis)
	Kit.add_ellipsoid(root, head + Vector3(0, -0.07, -0.255), Vector3(0.055, 0.04, 0.04), dark)
	Kit.add_ellipsoid(root, head + Vector3(0, -0.14, -0.06), Vector3(0.12, 0.08, 0.1), light)
	for s in [-1.0, 1.0]:
		Kit.add_ellipsoid(root, head + Vector3(s * 0.075, 0.025, -0.095), Vector3(0.035, 0.035, 0.03), dark)
		var ear_basis := Basis(Vector3.UP, s * deg_to_rad(70.0)) * Basis(Vector3.FORWARD, s * deg_to_rad(-55.0)) * Basis(Vector3.RIGHT, deg_to_rad(-15.0))
		Kit.add_ellipsoid(root, head + Vector3(s * 0.13, 0.06, 0.02), Vector3(0.06, 0.02, 0.14), fur, ear_basis)
		var p0 := head + Vector3(s * 0.06, 0.085, 0.02)
		var p1 := head + Vector3(s * 0.13, 0.21, 0.05)
		var p2 := head + Vector3(s * 0.21, 0.31, 0.0)
		var p3 := head + Vector3(s * 0.25, 0.39, -0.07)
		Kit.add_segment(root, p0, p1, 0.017, antler)
		Kit.add_segment(root, p1, p2, 0.015, antler)
		Kit.add_segment(root, p2, p3, 0.012, antler, 0.006)
		Kit.add_segment(root, p1, head + Vector3(s * 0.1, 0.33, -0.04), 0.012, antler, 0.005)
		Kit.add_segment(root, p2, head + Vector3(s * 0.19, 0.43, 0.04), 0.011, antler, 0.005)


## Cóndor andino: cuerpo negro con forma de alfil y las alas abiertas hacia
## arriba, con la banda blanca y las plumas de la punta separadas como dedos.
## Collar blanco, cabeza desnuda con carúncula y pico curvo.
static func _condor(root: Node3D, side: int) -> void:
	var top := _base(root, side, 0.16)
	var feathers := Kit.material(Color("#1b1b1d"), 0.6)
	var white := Kit.material(Color("#f2efe8"), 0.8)
	var skin := Kit.material(Color("#7d5c55"), 0.7)
	var comb := Kit.material(Color("#5a3d38"), 0.7)
	var beak := Kit.material(Color("#d9cfb8"), 0.5)
	var dark := Kit.material(Color("#0f0b09"), 0.3)
	Kit.add_lathe(root, PackedVector2Array([
		Vector2(0.15, top), Vector2(0.14, top + 0.06), Vector2(0.1, top + 0.2), Vector2(0.1, top + 0.3),
		Vector2(0.12, top + 0.36), Vector2(0.085, top + 0.43), Vector2(0.0, top + 0.45),
	]), feathers)
	# Cola corta y abierta detrás.
	Kit.add_ellipsoid(root, Vector3(0, top + 0.12, 0.13), Vector3(0.14, 0.03, 0.16), feathers, Basis(Vector3.RIGHT, deg_to_rad(-25.0)))
	for s in [-1.0, 1.0]:
		_condor_wing(root, Vector3(s * 0.07, top + 0.37, 0.02), s, feathers, white)
	Kit.add_torus(root, top + 0.45, 0.04, 0.105, white, 0.8)
	Kit.add_segment(root, Vector3(0, top + 0.45, 0), Vector3(0, top + 0.53, -0.01), 0.04, skin, 0.035)
	var head := Vector3(0, top + 0.57, -0.02)
	Kit.add_ellipsoid(root, head, Vector3(0.1, 0.1, 0.13), skin)
	Kit.add_ellipsoid(root, head + Vector3(0, 0.055, -0.01), Vector3(0.03, 0.05, 0.09), comb)
	Kit.add_segment(root, head + Vector3(0, -0.005, -0.055), head + Vector3(0, -0.02, -0.13), 0.026, beak, 0.012)
	Kit.add_segment(root, head + Vector3(0, -0.02, -0.13), head + Vector3(0, -0.045, -0.14), 0.012, beak, 0.004)
	for s in [-1.0, 1.0]:
		Kit.add_ellipsoid(root, head + Vector3(s * 0.04, 0.015, -0.04), Vector3(0.022, 0.022, 0.02), dark)


## Ala desplegada del cóndor, en el plano frontal (como el cóndor del escudo
## de Colombia), para que se lea desde la cámara de ambos bandos: panel ancho
## inclinado hacia arriba, banda blanca y cinco plumas primarias separadas
## en abanico. [param side_sign] = -1 (izquierda) o 1 (derecha).
static func _condor_wing(root: Node3D, shoulder: Vector3, side_sign: float, feathers: Material, white: Material) -> void:
	var lift := deg_to_rad(42.0)
	var span := Vector3(side_sign * cos(lift), sin(lift), 0.0)
	# Cuerda del ala: perpendicular a la envergadura, hacia abajo (borde de fuga).
	var chord := (Vector3.DOWN - span * Vector3.DOWN.dot(span)).normalized()
	# Base diestra: X = envergadura, Y = normal (mira al frente/atrás), Z = cuerda.
	var normal := chord.cross(span).normalized()
	var wing_basis := Basis(span, normal, chord)
	var length := 0.29
	Kit.add_ellipsoid(root, shoulder + span * length * 0.5 + chord * 0.06, Vector3(length, 0.03, 0.2), feathers, wing_basis)
	Kit.add_ellipsoid(root, shoulder + span * length * 0.46 + chord * 0.035, Vector3(length * 0.78, 0.04, 0.06), white, wing_basis)
	var tip := shoulder + span * length * 0.9 + chord * 0.05
	for i in 5:
		var angle := deg_to_rad(-12.0 + i * 15.0)
		var finger := (span * cos(angle) + chord * sin(angle)).normalized()
		var finger_basis := Basis(finger, normal, finger.cross(normal).normalized())
		Kit.add_ellipsoid(root, tip + finger * 0.06, Vector3(0.13, 0.014, 0.03), feathers, finger_basis)


## Oso de anteojos (torre): un oso completo sentado, con panza, brazos,
## patas, orejas redondas y las manchas crema alrededor de los ojos y en el
## pecho que le dan su nombre. Un aro de almenas en la base recuerda que es
## la torre.
static func _bear_tower(root: Node3D, side: int) -> void:
	var top := _base(root, side, 0.21)
	var stone := _side_material(side)
	var fur := Kit.material(Color("#1f1b18"), 0.9)
	var cream := Kit.material(Color("#e6d4a8"), 0.85)
	var muzzle := Kit.material(Color("#c9a77a"), 0.85)
	var dark := Kit.material(Color("#0d0a08"), 0.3)
	# Aro almenado bajo, en el color del bando.
	Kit.add_lathe(root, PackedVector2Array([
		Vector2(0.24, top), Vector2(0.24, top + 0.06), Vector2(0.0, top + 0.061),
	]), stone)
	for i in 8:
		var out := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 8.0 + PI / 8.0)
		var merlon := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.08, 0.06, 0.05)
		merlon.mesh = box
		merlon.material_override = stone
		merlon.transform = Transform3D(Basis.looking_at(out, Vector3.UP), Vector3(0, top + 0.09, 0) + out * 0.215)
		root.add_child(merlon)
	var seat := top + 0.06
	# Patas traseras al frente y cuerpo sentado.
	for s in [-1.0, 1.0]:
		Kit.add_ellipsoid(root, Vector3(s * 0.1, seat + 0.04, -0.1), Vector3(0.1, 0.08, 0.15), fur)
		Kit.add_ellipsoid(root, Vector3(s * 0.1, seat + 0.045, -0.165), Vector3(0.07, 0.04, 0.04), muzzle)
	Kit.add_ellipsoid(root, Vector3(0, seat + 0.17, 0.01), Vector3(0.34, 0.34, 0.3), fur)
	Kit.add_ellipsoid(root, Vector3(0, seat + 0.32, -0.04), Vector3(0.26, 0.2, 0.22), fur)
	# Mancha crema del pecho.
	Kit.add_ellipsoid(root, Vector3(0, seat + 0.27, -0.135), Vector3(0.13, 0.08, 0.03), cream, Basis(Vector3.RIGHT, deg_to_rad(-15.0)))
	# Brazos apoyados sobre la panza.
	for s in [-1.0, 1.0]:
		var arm_basis := Basis(Vector3.FORWARD, s * deg_to_rad(18.0)) * Basis(Vector3.RIGHT, deg_to_rad(28.0))
		Kit.add_ellipsoid(root, Vector3(s * 0.12, seat + 0.2, -0.1), Vector3(0.09, 0.2, 0.1), fur, arm_basis)
		Kit.add_ellipsoid(root, Vector3(s * 0.08, seat + 0.13, -0.16), Vector3(0.07, 0.05, 0.06), fur)
	var head := Vector3(0, seat + 0.47, -0.04)
	Kit.add_ellipsoid(root, head, Vector3(0.23, 0.21, 0.21), fur)
	Kit.add_ellipsoid(root, head + Vector3(0, -0.035, -0.105), Vector3(0.11, 0.09, 0.11), muzzle)
	Kit.add_ellipsoid(root, head + Vector3(0, -0.015, -0.16), Vector3(0.045, 0.035, 0.03), dark)
	for s in [-1.0, 1.0]:
		Kit.add_ellipsoid(root, head + Vector3(s * 0.09, 0.09, 0.0), Vector3(0.075, 0.075, 0.045), fur)
		Kit.add_ellipsoid(root, head + Vector3(s * 0.09, 0.09, -0.015), Vector3(0.04, 0.04, 0.02), muzzle)
		# "Anteojos": manchas crema alrededor de los ojos.
		Kit.add_ellipsoid(root, head + Vector3(s * 0.052, 0.03, -0.09), Vector3(0.07, 0.055, 0.03), cream, Basis(Vector3.FORWARD, s * deg_to_rad(-20.0)))
		Kit.add_ellipsoid(root, head + Vector3(s * 0.05, 0.032, -0.106), Vector3(0.026, 0.026, 0.02), dark)


## Danta (tapir) de montaña: pelaje oscuro, trompa corta, labio y bordes de
## las orejas blancos, sobre una columna elegante con tiara de dama.
static func _tapir(root: Node3D, side: int) -> void:
	var top := _base(root, side, 0.17)
	var column := _side_material(side)
	var fur := Kit.material(Color("#3a2c24"), 0.9)
	var white := Kit.material(Color("#efe9df"), 0.8)
	var dark := Kit.material(Color("#0d0a08"), 0.3)
	Kit.add_lathe(root, PackedVector2Array([
		Vector2(0.18, top), Vector2(0.15, top + 0.06), Vector2(0.105, top + 0.28), Vector2(0.14, top + 0.33),
		Vector2(0.12, top + 0.37), Vector2(0.0, top + 0.38),
	]), column)
	Kit.add_torus(root, top + 0.33, 0.11, 0.15, _gold(), 0.7)
	Kit.add_ellipsoid(root, Vector3(0, top + 0.43, 0.02), Vector3(0.22, 0.17, 0.25), fur)
	var head := Vector3(0, top + 0.53, -0.06)
	Kit.add_ellipsoid(root, head, Vector3(0.16, 0.16, 0.27), fur, Basis(Vector3.RIGHT, deg_to_rad(12.0)))
	Kit.add_segment(root, head + Vector3(0, -0.02, -0.11), head + Vector3(0, -0.07, -0.2), 0.045, fur, 0.028)
	Kit.add_ellipsoid(root, head + Vector3(0, -0.06, -0.15), Vector3(0.07, 0.03, 0.07), white)
	for s in [-1.0, 1.0]:
		var ear_basis := Basis(Vector3.FORWARD, s * deg_to_rad(-20.0))
		Kit.add_ellipsoid(root, head + Vector3(s * 0.07, 0.095, 0.05), Vector3(0.075, 0.095, 0.03), white, ear_basis)
		Kit.add_ellipsoid(root, head + Vector3(s * 0.07, 0.095, 0.045), Vector3(0.06, 0.08, 0.032), fur, ear_basis)
		Kit.add_ellipsoid(root, head + Vector3(s * 0.065, 0.03, -0.08), Vector3(0.025, 0.025, 0.02), dark)
	_crown(root, head.y + 0.085, 0.06, 5, 0.06, Vector3(0, 0, head.z + 0.02))


## Cazador furtivo: figura con chaqueta, sombrero de ala ancha y fusil.
static func _hunter(root: Node3D) -> void:
	var top := _base(root, NEUTRAL, 0.16)
	var pants := Kit.material(Color("#3d3a2c"), 0.9)
	var jacket := Kit.material(Color("#8e2b20"), 0.8)
	var skin := Kit.material(Color("#d9a77a"), 0.7)
	var hat := Kit.material(Color("#4a4a2e"), 0.85)
	var metal := Kit.material(Color("#2a2826"), 0.35, 0.7)
	var wood := Kit.material(Color("#6b4a2e"), 0.7)
	for s in [-1.0, 1.0]:
		Kit.add_segment(root, Vector3(s * 0.05, top, 0), Vector3(s * 0.05, top + 0.2, 0), 0.04, pants)
		Kit.add_segment(root, Vector3(s * 0.12, top + 0.42, 0), Vector3(s * 0.15, top + 0.24, -0.03), 0.033, jacket)
	var torso := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.11
	capsule.height = 0.34
	torso.mesh = capsule
	torso.material_override = jacket
	torso.position.y = top + 0.32
	root.add_child(torso)
	Kit.add_ellipsoid(root, Vector3(0, top + 0.53, 0), Vector3(0.15, 0.16, 0.15), skin)
	Kit.add_segment(root, Vector3(0, top + 0.575, 0), Vector3(0, top + 0.585, 0), 0.14, hat)
	Kit.add_segment(root, Vector3(0, top + 0.58, 0), Vector3(0, top + 0.66, 0), 0.075, hat, 0.06)
	Kit.add_segment(root, Vector3(0.11, top + 0.12, 0.08), Vector3(-0.13, top + 0.68, 0.08), 0.014, metal)
	Kit.add_segment(root, Vector3(0.11, top + 0.12, 0.08), Vector3(0.15, top + 0.04, 0.085), 0.028, wood)
