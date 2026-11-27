extends RefCounted
## Utilidades para construir modelos 3D por código: materiales compartidos,
## sólidos de revolución (torno), segmentos entre dos puntos, elipsoides,
## toros y rosetas de hojas como las del frailejón.
##
## Las usan los modelos de las piezas y la ambientación de la demo.

static var _materials: Dictionary = {}
static var _sphere: SphereMesh


## Material compartido por color, rugosidad y brillo metálico.
static func material(color: Color, roughness: float = 0.6, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f" % [color.to_html(), roughness, metallic]
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = roughness
		m.metallic = metallic
		_materials[key] = m
	return _materials[key]


## Sólido de revolución alrededor del eje Y. [param profile]: x = radio,
## y = altura, de abajo hacia arriba. Terminar en radio 0 cierra la tapa.
static func lathe(profile: PackedVector2Array, segments: int = 40) -> ArrayMesh:
	var n := profile.size()
	var profile_normals: Array[Vector2] = []
	for i in n:
		var tangent := (profile[mini(i + 1, n - 1)] - profile[maxi(i - 1, 0)]).normalized()
		profile_normals.append(Vector2(tangent.y, -tangent.x))
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for s in segments + 1:
		var angle := TAU * s / segments
		var c := cos(angle)
		var sn := sin(angle)
		for i in n:
			vertices.append(Vector3(profile[i].x * c, profile[i].y, profile[i].x * sn))
			normals.append(Vector3(profile_normals[i].x * c, profile_normals[i].y, profile_normals[i].x * sn).normalized())
	for s in segments:
		for i in n - 1:
			var a := s * n + i
			var b := a + n
			indices.append_array([a, b, a + 1, a + 1, b, b + 1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func add_lathe(parent: Node3D, profile: PackedVector2Array, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = lathe(profile)
	instance.material_override = mat
	parent.add_child(instance)
	return instance


## Cilindro entre dos puntos (astas, tallos, picos...). Con [param tip_radius]
## distinto del radio se vuelve un cono truncado.
static func add_segment(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material, tip_radius: float = -1.0) -> MeshInstance3D:
	var direction := b - a
	var length := direction.length()
	var y := direction / length
	var x := y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y)
	var cylinder := CylinderMesh.new()
	cylinder.height = length
	cylinder.bottom_radius = radius
	cylinder.top_radius = radius if tip_radius < 0.0 else tip_radius
	cylinder.radial_segments = 10
	cylinder.rings = 1
	var instance := MeshInstance3D.new()
	instance.mesh = cylinder
	instance.material_override = mat
	instance.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5)
	parent.add_child(instance)
	return instance


## Elipsoide con dimensiones totales [param size], rotado por [param basis].
static func add_ellipsoid(parent: Node3D, center: Vector3, size: Vector3, mat: Material, basis: Basis = Basis.IDENTITY) -> MeshInstance3D:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 0.5
		_sphere.height = 1.0
		_sphere.radial_segments = 16
		_sphere.rings = 8
	var instance := MeshInstance3D.new()
	instance.mesh = _sphere
	instance.material_override = mat
	instance.transform = Transform3D(basis * Basis.from_scale(size), center)
	parent.add_child(instance)
	return instance


## Anillo horizontal (toro) centrado en el eje Y a la altura [param y].
static func add_torus(parent: Node3D, y: float, inner_radius: float, outer_radius: float, mat: Material, flatten: float = 1.0) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = inner_radius
	torus.outer_radius = outer_radius
	torus.rings = 32
	torus.ring_segments = 8
	var instance := MeshInstance3D.new()
	instance.mesh = torus
	instance.material_override = mat
	instance.position.y = y
	instance.scale.y = flatten
	parent.add_child(instance)
	return instance


## Hoja alargada que sale de [param center] en la dirección [param angle]
## (alrededor de Y), levantada [param tilt] radianes sobre la horizontal.
static func add_leaf(parent: Node3D, center: Vector3, angle: float, tilt: float, length: float, width: float, mat: Material) -> void:
	var rotation := Basis(Vector3.UP, angle) * Basis(Vector3.RIGHT, -tilt)
	add_ellipsoid(parent, center + rotation * Vector3(0.0, 0.0, length * 0.45),
			Vector3(width, width * 0.32, length), mat, rotation)


## Roseta de frailejón: dos coronas de hojas vellosas.
static func add_rosette(parent: Node3D, center: Vector3, length: float, leaves: int, outer: Material, inner: Material, droop: bool = false) -> void:
	var outer_tilt := deg_to_rad(-25.0 if droop else 28.0)
	var inner_tilt := deg_to_rad(10.0 if droop else 58.0)
	for i in leaves:
		add_leaf(parent, center, TAU * i / leaves, outer_tilt, length, length * 0.3, outer)
	var inner_count := maxi(5, int(leaves * 0.65))
	for i in inner_count:
		add_leaf(parent, center, TAU * (i + 0.5) / inner_count, inner_tilt, length * 0.65, length * 0.26, inner)
