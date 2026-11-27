extends RefCounted
## Utilidades de mallas para la ambientación de la demo: vegetación, rocas,
## troncos, pasto y partículas. Las formas básicas (torno, segmentos,
## elipsoides, rosetas) vienen de scripts/pieces/mesh_kit.gd, que comparten
## con los modelos de las piezas.

const Kit := preload("res://scripts/pieces/mesh_kit.gd")

static var _sphere: SphereMesh


static func material(color: Color, roughness: float = 0.6, metallic: float = 0.0) -> StandardMaterial3D:
	return Kit.material(color, roughness, metallic)


static func lathe(profile: PackedVector2Array, segments: int = 40) -> ArrayMesh:
	return Kit.lathe(profile, segments)


static func add_lathe(parent: Node3D, profile: PackedVector2Array, mat: Material) -> MeshInstance3D:
	return Kit.add_lathe(parent, profile, mat)


static func add_segment(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material, tip_radius: float = -1.0) -> MeshInstance3D:
	return Kit.add_segment(parent, a, b, radius, mat, tip_radius)


static func add_ellipsoid(parent: Node3D, center: Vector3, size: Vector3, mat: Material, basis: Basis = Basis.IDENTITY) -> MeshInstance3D:
	return Kit.add_ellipsoid(parent, center, size, mat, basis)


static func add_leaf(parent: Node3D, center: Vector3, angle: float, tilt: float, length: float, width: float, mat: Material) -> void:
	Kit.add_leaf(parent, center, angle, tilt, length, width, mat)


static func add_rosette(parent: Node3D, center: Vector3, length: float, leaves: int, outer: Material, inner: Material, droop: bool = false) -> void:
	Kit.add_rosette(parent, center, length, leaves, outer, inner, droop)


# ---------------------------------------------------------------------------
# Mallas combinadas para vegetación masiva (MultiMesh)
# ---------------------------------------------------------------------------
# Cada "parte" es [Mesh, Transform3D, Material]. merge() junta las partes en
# una sola malla con una superficie por material, lista para dibujar cientos
# de copias con MultiMeshInstance3D sin crear miles de nodos.

static var _low_sphere: SphereMesh


static func merge(parts: Array) -> ArrayMesh:
	var groups := {}
	for part in parts:
		if not groups.has(part[2]):
			groups[part[2]] = []
		groups[part[2]].append(part)
	var result := ArrayMesh.new()
	for mat in groups:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in groups[mat]:
			tool.append_from(part[0], 0, part[1])
		tool.commit(result)
		result.surface_set_material(result.get_surface_count() - 1, mat)
	return result


static func part_ellipsoid(center: Vector3, size: Vector3, mat: Material, basis: Basis = Basis.IDENTITY, low_poly: bool = false) -> Array:
	var mesh: Mesh
	if low_poly:
		if _low_sphere == null:
			_low_sphere = SphereMesh.new()
			_low_sphere.radius = 0.5
			_low_sphere.height = 1.0
			_low_sphere.radial_segments = 7
			_low_sphere.rings = 4
		mesh = _low_sphere
	else:
		if _sphere == null:
			_sphere = SphereMesh.new()
			_sphere.radius = 0.5
			_sphere.height = 1.0
			_sphere.radial_segments = 16
			_sphere.rings = 8
		mesh = _sphere
	return [mesh, Transform3D(basis * Basis.from_scale(size), center), mat]


static func part_segment(a: Vector3, b: Vector3, radius: float, mat: Material, tip_radius: float = -1.0) -> Array:
	var direction := b - a
	var length := direction.length()
	var y := direction / length
	var x := y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var cylinder := CylinderMesh.new()
	cylinder.height = length
	cylinder.bottom_radius = radius
	cylinder.top_radius = radius if tip_radius < 0.0 else tip_radius
	cylinder.radial_segments = 8
	cylinder.rings = 1
	return [cylinder, Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5), mat]


static func part_leaf(center: Vector3, angle: float, tilt: float, length: float, width: float, mat: Material) -> Array:
	var rotation := Basis(Vector3.UP, angle) * Basis(Vector3.RIGHT, -tilt)
	return part_ellipsoid(center + rotation * Vector3(0.0, 0.0, length * 0.45),
			Vector3(width, width * 0.3, length), mat, rotation)


## Frailejón de paisaje: tronco con collar de hojas secas, roseta y flores.
static func frailejon_mesh(height: float, size: float, burnt: bool = false) -> ArrayMesh:
	var trunk := material(Color("#3d3128") if burnt else Color("#6e5b47"), 1.0)
	var collar := material(Color("#2c241e") if burnt else Color("#584736"), 1.0)
	var outer := material(Color("#6d6a55") if burnt else Color("#a9b98f"), 0.85)
	var inner := material(Color("#8a8670") if burnt else Color("#d3dcba"), 0.8)
	var flower := material(Color("#f2c94c"), 0.6)
	var parts := []
	parts.append(part_segment(Vector3.ZERO, Vector3(0, height, 0), size * 0.32, trunk, size * 0.27))
	for i in 3:
		parts.append(part_ellipsoid(Vector3(0, height * (0.45 + i * 0.2), 0), Vector3(size * 0.75, size * 0.35, size * 0.75), collar))
	var crown := Vector3(0, height, 0)
	for i in 12:
		parts.append(part_leaf(crown, TAU * i / 12.0, deg_to_rad(25.0), size, size * 0.3, outer))
	for i in 8:
		parts.append(part_leaf(crown, TAU * (i + 0.5) / 8.0, deg_to_rad(58.0), size * 0.65, size * 0.26, inner))
	if not burnt:
		for i in 3:
			var tip := crown + Vector3(0, size * 0.75, 0) + Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 3.0) * size * 0.25
			parts.append(part_segment(crown, tip, size * 0.03, inner))
			parts.append(part_ellipsoid(tip, Vector3.ONE * size * 0.22, flower))
	return merge(parts)


## Árbol de selva: tronco con raíces y copa de varias capas.
static func tree_mesh(height: float, rng: RandomNumberGenerator) -> ArrayMesh:
	var bark := material(Color("#4f3b2a"), 0.95)
	var leaves_dark := material(Color("#24481f"), 0.9)
	var leaves_light := material(Color("#3f6f2c"), 0.9)
	var parts := []
	parts.append(part_segment(Vector3.ZERO, Vector3(0, height, 0), 0.32, bark, 0.18))
	for i in 4:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 4.0 + 0.4)
		parts.append(part_segment(Vector3(0, 0.6, 0), direction * 0.8 + Vector3(0, -0.05, 0), 0.14, bark, 0.05))
	for i in 3:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 3.0 + rng.randf())
		parts.append(part_segment(Vector3(0, height * 0.7, 0), Vector3(0, height * 0.92, 0) + direction * 1.4, 0.1, bark, 0.05))
	for i in 7:
		var offset := Vector3(rng.randf_range(-1.5, 1.5), rng.randf_range(-0.4, 1.1), rng.randf_range(-1.5, 1.5))
		var r := rng.randf_range(1.6, 2.5)
		parts.append(part_ellipsoid(Vector3(0, height, 0) + offset, Vector3(r, r * 0.65, r),
				leaves_dark if i % 2 == 0 else leaves_light, Basis.IDENTITY, true))
	return merge(parts)


## Palma de cera: tronco blanquecino muy alto y corona de hojas colgantes.
static func palm_mesh(height: float) -> ArrayMesh:
	var trunk := material(Color("#d4cdbd"), 0.75)
	var ring := material(Color("#a69f8f"), 0.8)
	var frond := material(Color("#3f6b31"), 0.85)
	var frond_light := material(Color("#5f8a3f"), 0.85)
	var parts := []
	parts.append(part_segment(Vector3.ZERO, Vector3(0, height, 0), 0.2, trunk, 0.15))
	for i in 10:
		parts.append(part_ellipsoid(Vector3(0, height * (0.1 + i * 0.085), 0), Vector3(0.42, 0.05, 0.42), ring))
	var top := Vector3(0, height, 0)
	for i in 11:
		var angle := TAU * i / 11.0
		var tilt := deg_to_rad(-35.0 if i % 2 == 0 else -15.0)
		parts.append(part_leaf(top, angle, tilt, 2.6, 0.55, frond if i % 2 == 0 else frond_light))
	for i in 5:
		parts.append(part_leaf(top, TAU * i / 5.0 + 0.3, deg_to_rad(55.0), 1.4, 0.35, frond_light))
	return merge(parts)


## Arbusto redondeado; con flores amarillas es un retamo espinoso.
static func bush_mesh(color: Color, rng: RandomNumberGenerator, flowers: bool) -> ArrayMesh:
	var leaves := material(color, 0.9)
	var leaves_alt := material(color.lightened(0.15), 0.9)
	var flower := material(Color("#f2c94c"), 0.6)
	var parts := []
	for i in 5:
		var offset := Vector3(rng.randf_range(-0.45, 0.45), rng.randf_range(0.25, 0.55), rng.randf_range(-0.45, 0.45))
		var r := rng.randf_range(0.55, 0.9)
		parts.append(part_ellipsoid(offset, Vector3(r, r * 0.8, r), leaves if i % 2 == 0 else leaves_alt, Basis.IDENTITY, true))
		if flowers:
			for j in 5:
				var dot := offset + Vector3(rng.randf_range(-0.3, 0.3), r * 0.38, rng.randf_range(-0.3, 0.3))
				parts.append(part_ellipsoid(dot, Vector3.ONE * 0.1, flower, Basis.IDENTITY, true))
	return merge(parts)


## Roca facetada (esferas de pocos polígonos deformadas).
static func rock_mesh(color: Color, rng: RandomNumberGenerator) -> ArrayMesh:
	var stone := material(color, 0.95)
	var stone_alt := material(color.darkened(0.15), 0.95)
	var parts := []
	for i in rng.randi_range(2, 3):
		var size := Vector3(rng.randf_range(0.6, 1.2), rng.randf_range(0.4, 0.8), rng.randf_range(0.6, 1.1))
		var offset := Vector3(rng.randf_range(-0.35, 0.35), size.y * 0.25, rng.randf_range(-0.35, 0.35))
		var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.3, 0.3))
		parts.append(part_ellipsoid(offset, size, stone if i == 0 else stone_alt, basis, true))
	return merge(parts)


## Árbol muerto: tronco seco con ramas desnudas.
static func dead_tree_mesh(height: float, rng: RandomNumberGenerator) -> ArrayMesh:
	var bark := material(Color("#3b322b"), 1.0)
	var parts := []
	var top := Vector3(rng.randf_range(-0.3, 0.3), height, rng.randf_range(-0.3, 0.3))
	parts.append(part_segment(Vector3.ZERO, top, 0.2, bark, 0.06))
	for i in 5:
		var from := top * rng.randf_range(0.4, 0.85)
		var to := from + Vector3(rng.randf_range(-1.3, 1.3), rng.randf_range(0.4, 1.3), rng.randf_range(-1.3, 1.3))
		parts.append(part_segment(from, to, 0.08, bark, 0.015))
		parts.append(part_segment(to, to + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.2, 0.6), rng.randf_range(-0.5, 0.5)), 0.03, bark, 0.008))
	return merge(parts)


## Tocón de árbol talado.
static func stump_mesh() -> ArrayMesh:
	var bark := material(Color("#4f3b2a"), 0.95)
	var wood := material(Color("#c9a77a"), 0.8)
	return merge([
		part_segment(Vector3.ZERO, Vector3(0, 0.45, 0), 0.34, bark, 0.3),
		part_segment(Vector3(0, 0.45, 0), Vector3(0, 0.47, 0), 0.29, wood),
		part_segment(Vector3(0.2, 0.05, 0), Vector3(0.6, -0.05, 0.1), 0.12, bark, 0.04),
	])


## Tronco caído.
static func log_mesh() -> ArrayMesh:
	var bark := material(Color("#5a4330"), 0.95)
	var wood := material(Color("#c9a77a"), 0.8)
	return merge([
		part_segment(Vector3(-1.4, 0.3, 0), Vector3(1.4, 0.3, 0), 0.3, bark),
		part_segment(Vector3(1.4, 0.3, 0), Vector3(1.42, 0.3, 0), 0.27, wood),
		part_segment(Vector3(-1.42, 0.3, 0), Vector3(-1.4, 0.3, 0), 0.27, wood),
	])


## Mata de pasto de 1 unidad de alto (la base en y = 0), para el shader de viento.
static func grass_clump_mesh(blades: int = 7) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for b in blades:
		var angle := TAU * b / blades + rng.randf_range(-0.3, 0.3)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var side := Vector3(-direction.z, 0.0, direction.x)
		var lean := rng.randf_range(0.15, 0.45)
		var height := rng.randf_range(0.7, 1.0)
		var width := 0.045
		var base := direction * 0.05
		var points := []
		for s in 4:
			var t := s / 3.0
			var center := base + direction * lean * t * t + Vector3.UP * height * t
			points.append([center - side * width * (1.0 - t), center + side * width * (1.0 - t)])
		for s in 3:
			var a: Array = points[s]
			var c: Array = points[s + 1]
			var normal := (direction + Vector3.UP).normalized()
			for v in [a[0], a[1], c[0], a[1], c[1], c[0]]:
				tool.set_normal(normal)
				tool.add_vertex(v)
	return tool.commit()


## Material para partículas: punto suave que brilla (aditivo) o niebla (mezcla).
static func soft_particle_material(additive: bool) -> StandardMaterial3D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	# BILLBOARD_PARTICLES pierde la escala de cada partícula en el renderer de
	# compatibilidad; el billboard normal conservando la escala sí funciona.
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = texture
	mat.disable_receive_shadows = true
	return mat
