extends RefCounted
## Terreno procedural para la demo: un claro plano bajo el tablero, colinas
## alrededor, una cordillera lejana y depresiones con agua (lagunas o río).
##
## [method height] se usa tanto para construir la malla como para apoyar la
## vegetación sobre el suelo.

## Altura del claro: la base del tablero se apoya aquí.
const FLAT_Y := -0.37
const SIZE := 190.0
const RESOLUTION := 150

var hills_amp := 2.5
var mountain_amp := 20.0
var flat_radius := 9.5
var ring_start := 26.0
var ring_end := 75.0
## Alto de las terrazas de erosión (0 = sin terrazas).
var terrace := 0.0
var water_level := -0.9
## Lagunas: Vector3(x, z, radio).
var lakes: Array = []
## Z media de un río que cruza de lado a lado (INF = sin río).
var river_z := INF
var river_width := 3.2
## Zonas de tierra removida (minería, tala): Vector3(x, z, radio).
var scars: Array = []
## Proporción de parches quemados (0 = ninguno).
var scorch := 0.0
## Colores: clearing, low, low_alt, slope, high, peak, shore, scar, scorched.
var palette := {}
var peak_from := 18.0

var _hills := FastNoiseLite.new()
var _ridges := FastNoiseLite.new()
var _detail := FastNoiseLite.new()


func _init(config: Dictionary) -> void:
	for key in config:
		set(key, config[key])
	var seed_value: int = config.get("seed", 1)
	_hills.seed = seed_value
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.frequency = config.get("hills_freq", 0.035)
	_hills.fractal_octaves = 4
	_ridges.seed = seed_value + 7
	_ridges.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ridges.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridges.frequency = config.get("mountain_freq", 0.018)
	_ridges.fractal_octaves = 5
	_detail.seed = seed_value + 13
	_detail.frequency = 0.08
	_detail.fractal_octaves = 3


## Centro del río en la coordenada x.
func river_center(x: float) -> float:
	return river_z + sin(x * 0.07) * 2.5 + sin(x * 0.023 + 1.3) * 3.5


## Altura del suelo en (x, z).
func height(x: float, z: float) -> float:
	var r := sqrt(x * x + z * z)
	var near := smoothstep(flat_radius, flat_radius + 12.0, r)
	var h := FLAT_Y + (_hills.get_noise_2d(x, z) * 0.5 + 0.35) * hills_amp * near
	var ring := smoothstep(ring_start, ring_end, r)
	if ring > 0.0 and mountain_amp > 0.0:
		var ridge := _ridges.get_noise_2d(x, z) * 0.5 + 0.5
		h += ridge * ridge * mountain_amp * ring
	if terrace > 0.0 and h > 0.8:
		var level := h / terrace
		var stepped := (floorf(level) + smoothstep(0.7, 1.0, level - floorf(level))) * terrace
		h = lerpf(h, stepped, 0.7)
	for lake in lakes:
		var d: float = Vector2(x - lake.x, z - lake.y).length() / lake.z
		if d < 1.6:
			h = lerpf(water_level - 1.1, h, smoothstep(0.5, 1.45, d))
	if river_z != INF and r > flat_radius:
		var d := absf(z - river_center(x)) / river_width
		if d < 1.8:
			h = lerpf(water_level - 0.9, h, smoothstep(0.45, 1.6, d))
	return h


## true si en (x, z) hay agua.
func is_water(x: float, z: float) -> bool:
	return height(x, z) < water_level + 0.12


## Malla del terreno con colores por vértice (ya en espacio lineal).
func build_mesh() -> ArrayMesh:
	var n := RESOLUTION + 1
	var step := SIZE / RESOLUTION
	var half := SIZE * 0.5
	var heights := PackedFloat32Array()
	heights.resize(n * n)
	for j in n:
		for i in n:
			heights[j * n + i] = height(-half + i * step, -half + j * step)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	vertices.resize(n * n)
	normals.resize(n * n)
	colors.resize(n * n)
	for j in n:
		for i in n:
			var k := j * n + i
			var x := -half + i * step
			var z := -half + j * step
			var h := heights[k]
			var hl := heights[j * n + maxi(i - 1, 0)]
			var hr := heights[j * n + mini(i + 1, n - 1)]
			var hd := heights[maxi(j - 1, 0) * n + i]
			var hu := heights[mini(j + 1, n - 1) * n + i]
			var normal := Vector3(hl - hr, 2.0 * step, hd - hu).normalized()
			vertices[k] = Vector3(x, h, z)
			normals[k] = normal
			colors[k] = color_at(x, z, h, 1.0 - normal.y).srgb_to_linear()

	var indices := PackedInt32Array()
	indices.resize(RESOLUTION * RESOLUTION * 6)
	var w := 0
	for j in RESOLUTION:
		for i in RESOLUTION:
			var a := j * n + i
			var c := a + n
			indices[w] = a
			indices[w + 1] = a + 1
			indices[w + 2] = c
			indices[w + 3] = a + 1
			indices[w + 4] = c + 1
			indices[w + 5] = c
			w += 6

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Color del suelo según altura, pendiente, cercanía al agua y zonas especiales.
func color_at(x: float, z: float, h: float, slope: float) -> Color:
	var r := sqrt(x * x + z * z)
	var n := _detail.get_noise_2d(x, z) * 0.5 + 0.5
	var c: Color = (palette["low"] as Color).lerp(palette["low_alt"], smoothstep(0.3, 0.7, n))
	c = (palette["clearing"] as Color).lerp(c, smoothstep(6.5, 10.5, r))
	c = c.lerp(palette["slope"], smoothstep(0.25, 0.55, slope))
	c = c.lerp(palette["high"], smoothstep(5.0, 13.0, h))
	c = c.lerp(palette["peak"], smoothstep(peak_from, peak_from + 6.0, h))
	c = c.lerp(palette["shore"], 1.0 - smoothstep(water_level + 0.1, water_level + 0.45, h))
	for scar in scars:
		var d: float = Vector2(x - scar.x, z - scar.y).length() / scar.z
		c = c.lerp(palette["scar"], (1.0 - smoothstep(0.65, 1.0, d)) * (0.75 + 0.25 * n))
	if scorch > 0.0:
		var s := _detail.get_noise_2d(x * 0.35 + 300.0, z * 0.35) * 0.5 + 0.5
		c = c.lerp(palette["scorched"], smoothstep(1.0 - scorch, 1.1 - scorch, s) * smoothstep(7.0, 10.0, r))
	return c
