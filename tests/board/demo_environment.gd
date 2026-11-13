extends Node3D
## Ambientación 3D para la demo del tablero: cielo, luz, terreno con colinas
## y cordillera, agua, vegetación con viento, niebla, nubes, partículas y
## fauna, distinta para cada bioma.
##
## Es solo para la demo. Los escenarios reales de cada nivel corresponden al
## módulo de biomas (scenes/biomes), que puede reutilizar estas piezas.

const Meshes := preload("res://tests/board/demo_meshes.gd")
const Terrain := preload("res://tests/board/demo_terrain.gd")
const Creatures := preload("res://tests/board/demo_creatures.gd")
const TERRAIN_SHADER := preload("res://tests/board/shaders/terrain.gdshader")
const WATER_SHADER := preload("res://tests/board/shaders/water.gdshader")
const MIST_SHADER := preload("res://tests/board/shaders/mist.gdshader")
const GRASS_SHADER := preload("res://tests/board/shaders/grass.gdshader")

## Medio lado del área bajo el tablero (marco incluido) donde no va vegetación.
const BOARD_CLEARANCE := 4.95

var _environment := Environment.new()
var _sky_material := ProceduralSkyMaterial.new()
var _sun := DirectionalLight3D.new()
var _content: Node3D
var _terrain: Terrain
var _rng := RandomNumberGenerator.new()
var _grass_mesh: ArrayMesh


func _ready() -> void:
	var sky := Sky.new()
	sky.sky_material = _sky_material
	_environment.background_mode = Environment.BG_SKY
	_environment.sky = sky
	# Luz ambiental de color controlado: la del cielo procedural lava los
	# colores en el renderer de compatibilidad.
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_environment.tonemap_white = 3.0
	_environment.glow_enabled = true
	_environment.glow_intensity = 0.55
	_environment.glow_bloom = 0.02
	_environment.glow_hdr_threshold = 1.1
	var world := WorldEnvironment.new()
	world.environment = _environment
	add_child(world)

	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 45.0
	_sun.shadow_blur = 1.5
	add_child(_sun)
	_grass_mesh = Meshes.grass_clump_mesh()


func apply_preset(preset: StringName) -> void:
	if _content:
		# Se saca del árbol de inmediato para que el nuevo bioma conserve el nombre.
		remove_child(_content)
		_content.queue_free()
	_content = Node3D.new()
	_content.name = "Biome"
	add_child(_content)
	_rng.seed = hash(preset)
	match preset:
		&"amazonia":
			_build_amazonia()
		&"santuario":
			_build_santuario()
		&"clasico":
			_build_clasico()
		_:
			_build_paramo()


# ---------------------------------------------------------------------------
# Biomas
# ---------------------------------------------------------------------------

## Páramo de Sumapaz: laguna, frailejonal, pajonal dorado, neblina y cóndores.
func _build_paramo() -> void:
	_set_lighting(Color("#56708b"), Color("#c9d3d0"), Color("#cfd8d6"), Color("#fff1d6"), 0.8, Vector3(-36, -40, 0))
	_make_terrain({
		"seed": 11, "hills_amp": 2.8, "mountain_amp": 28.0, "ring_start": 24.0, "ring_end": 70.0, "peak_from": 20.0,
		"lakes": [Vector3(-13.0, -9.0, 5.0), Vector3(26.0, -34.0, 8.0)],
		"palette": {
			"clearing": Color("#7f7b55"), "low": Color("#8c8550"), "low_alt": Color("#6f7b47"),
			"slope": Color("#6c675c"), "high": Color("#77756a"), "peak": Color("#b2b4ae"),
			"shore": Color("#3f4a32"), "scar": Color("#5a4a36"), "scorched": Color("#2e2620"),
		},
	})
	_add_water(Color("#0f2e38"), Color("#3c6670"))
	_add_grass(7500, Color("#4f4a26"), Color("#d2bf7c"), 5.0, 45.0, Vector2(0.35, 0.8))
	_add_flowers(450, [Color("#8e6bbf"), Color("#f2c94c"), Color("#efe9dc")], 6.4, 18.0)
	var frailejones := [Meshes.frailejon_mesh(0.8, 0.38), Meshes.frailejon_mesh(1.4, 0.45), Meshes.frailejon_mesh(2.2, 0.5)]
	_scatter_variants(frailejones, 30, 7.0, 14.0, Vector2(0.8, 1.15), {"tall": true})
	_scatter_variants(frailejones, 140, 12.0, 50.0, Vector2(0.8, 1.3), {"tall": true})
	var rocks := [Meshes.rock_mesh(Color("#77736a"), _rng), Meshes.rock_mesh(Color("#6a675f"), _rng)]
	_scatter_variants(rocks, 20, 7.0, 15.0, Vector2(0.35, 0.8), {})
	_scatter_variants(rocks, 35, 15.0, 60.0, Vector2(0.8, 2.4), {})
	_add_mist(1.1, Color("#eef2ee"), 0.4, 0.07, 9.5, 60.0, 0.45)
	_add_mist(4.5, Color("#f2f5f2"), 0.5, 0.035, 14.0, 90.0, 0.42)
	_add_clouds(Color("#f5f7f6"), 0.85)
	_add_particles(&"mist")
	# Vuelan por encima de la cámara de juego: en partida solo pasa su sombra.
	_add_bird(&"condor", 11.0, 18.0, 0.13, 0.0)
	_add_bird(&"condor", 15.0, 21.0, -0.1, 0.45)


## Amazonía: río, selva densa, palmas de cera, claro deforestado y guacamayas.
func _build_amazonia() -> void:
	_set_lighting(Color("#3d6d8f"), Color("#c4dcb9"), Color("#b9d1ad"), Color("#fff3d2"), 0.85, Vector3(-48, -25, 0))
	var scar := Vector3(-13.5, 3.0, 5.5)
	_make_terrain({
		"seed": 23, "hills_amp": 2.2, "mountain_amp": 12.0, "ring_start": 30.0, "ring_end": 80.0, "peak_from": 40.0,
		"river_z": -12.5, "river_width": 3.0, "scars": [scar],
		"palette": {
			"clearing": Color("#4f5a2c"), "low": Color("#2f5a24"), "low_alt": Color("#417231"),
			"slope": Color("#3c5a28"), "high": Color("#2a4a22"), "peak": Color("#2a4a22"),
			"shore": Color("#5a4630"), "scar": Color("#7a5432"), "scorched": Color("#2e2620"),
		},
	})
	_add_water(Color("#2b2614"), Color("#4f4a26"), 0.35)
	_add_grass(6500, Color("#1d3d16"), Color("#6fa04a"), 5.0, 40.0, Vector2(0.3, 0.7), {"avoid": [scar]})
	_add_flowers(260, [Color("#e0402a"), Color("#f28c28"), Color("#f2c94c")], 6.4, 16.0, {"avoid": [scar]})
	var trees: Array = []
	for i in 4:
		trees.append(Meshes.tree_mesh(_rng.randf_range(4.5, 7.0), _rng))
	_scatter_variants(trees, 170, 13.0, 75.0, Vector2(0.8, 1.3), {"tall": true, "avoid": [scar]})
	_scatter_variants([Meshes.palm_mesh(9.0), Meshes.palm_mesh(11.0)], 22, 14.0, 60.0, Vector2(0.9, 1.1), {"tall": true, "avoid": [scar]})
	var bushes := [Meshes.bush_mesh(Color("#2f5a26"), _rng, false), Meshes.bush_mesh(Color("#3c6a2c"), _rng, false)]
	_scatter_variants(bushes, 90, 7.5, 30.0, Vector2(0.6, 1.3), {"avoid": [scar]})
	# Frente de deforestación: tocones y troncos en la tierra removida.
	_scatter_variants([Meshes.stump_mesh()], 16, 0.0, scar.z * 0.85, Vector2(0.8, 1.3), {"around": Vector2(scar.x, scar.y)})
	_scatter_variants([Meshes.log_mesh()], 5, 0.0, scar.z * 0.7, Vector2(0.8, 1.1), {"around": Vector2(scar.x, scar.y)})
	_add_mist(2.4, Color("#e8f0e0"), 0.3, 0.06, 10.0, 60.0, 0.48)
	_add_mist(7.0, Color("#eef4ea"), 0.45, 0.03, 16.0, 90.0, 0.44)
	_add_clouds(Color("#ffffff"), 0.9)
	_add_particles(&"fireflies")
	for i in 3:
		_add_bird(&"macaw", 7.0 + i * 1.6, 4.2 + i * 0.7, 0.42 * (1.0 if i % 2 == 0 else -1.0), i * 0.33)
	for i in 6:
		var butterfly := Creatures.Butterfly.new()
		butterfly.phase = i / 6.0
		butterfly.radius = 6.4 + (i % 3) * 0.6
		_content.add_child(butterfly)


## Santuario en crisis: tierra seca y quemada, árboles muertos, retamo,
## humo, brasas, gallinazos e hipopótamos en la charca.
func _build_santuario() -> void:
	_set_lighting(Color("#6a5652"), Color("#d9b896"), Color("#cfb08f"), Color("#ffe2bd"), 0.78, Vector3(-30, -55, 0))
	var pond := Vector3(-12.5, -8.0, 4.8)
	_make_terrain({
		"seed": 37, "hills_amp": 2.0, "mountain_amp": 17.0, "ring_start": 24.0, "ring_end": 70.0, "peak_from": 30.0,
		"terrace": 2.2, "lakes": [pond], "scorch": 0.38,
		"palette": {
			"clearing": Color("#7d6c52"), "low": Color("#8c7a58"), "low_alt": Color("#76654a"),
			"slope": Color("#7d6048"), "high": Color("#8a6c50"), "peak": Color("#a58c6c"),
			"shore": Color("#4a3e30"), "scar": Color("#5a4632"), "scorched": Color("#2e2925"),
		},
	})
	_add_water(Color("#2a261b"), Color("#4a4430"), 0.3)
	_add_grass(4000, Color("#5a4a26"), Color("#c8a860"), 5.0, 40.0, Vector2(0.3, 0.6))
	var dead := [Meshes.dead_tree_mesh(3.0, _rng), Meshes.dead_tree_mesh(4.0, _rng), Meshes.dead_tree_mesh(5.0, _rng)]
	_scatter_variants(dead, 40, 9.0, 60.0, Vector2(0.8, 1.3), {"tall": true})
	var retamo := [Meshes.bush_mesh(Color("#5f6b33"), _rng, true), Meshes.bush_mesh(Color("#6b6a35"), _rng, true)]
	_scatter_variants(retamo, 70, 7.5, 35.0, Vector2(0.6, 1.2), {})
	_scatter_variants([Meshes.rock_mesh(Color("#8a6a50"), _rng), Meshes.rock_mesh(Color("#7a5a44"), _rng)], 50, 7.0, 60.0, Vector2(0.4, 2.0), {})
	_scatter_variants([Meshes.frailejon_mesh(1.0, 0.42, true), Meshes.frailejon_mesh(1.6, 0.45, true)], 20, 8.0, 30.0, Vector2(0.9, 1.2), {"tall": true})
	for i in 3:
		var hippo := Creatures.Hippo.new()
		var angle := TAU * i / 3.0 + 0.5
		hippo.position = Vector3(pond.x + cos(angle) * pond.z * 0.45, 0.0, pond.y + sin(angle) * pond.z * 0.4)
		hippo.rotation.y = _rng.randf() * TAU
		hippo.water_level = _terrain.water_level
		hippo.phase = i / 3.0
		_content.add_child(hippo)
	for spot in [Vector3(-32, 0, -40), Vector3(28, 0, -46), Vector3(-50, 0, -12)]:
		_add_smoke(Vector3(spot.x, _terrain.height(spot.x, spot.z), spot.z))
	_add_mist(3.0, Color("#b9a08a"), 0.32, 0.05, 11.0, 70.0, 0.46)
	_add_clouds(Color("#d8c0a8"), 0.75)
	_add_particles(&"embers")
	_add_particles(&"ash")
	for i in 4:
		_add_bird(&"vulture", 9.0 + i * 1.5, 16.0 + i * 1.2, 0.16 * (1.0 if i < 2 else -1.0), i * 0.25)


## Clásico: estudio oscuro y sobrio, sin vegetación.
func _build_clasico() -> void:
	_set_lighting(Color("#1c1c22"), Color("#34343c"), Color("#25252b"), Color("#ffffff"), 0.85, Vector3(-55, -30, 0), false)
	_make_terrain({
		"seed": 5, "hills_amp": 0.0, "mountain_amp": 0.0,
		"palette": {
			"clearing": Color("#5c5c66"), "low": Color("#2e2e35"), "low_alt": Color("#313139"),
			"slope": Color("#26262c"), "high": Color("#26262c"), "peak": Color("#26262c"),
			"shore": Color("#26262c"), "scar": Color("#26262c"), "scorched": Color("#26262c"),
		},
	}, 0.08, 0.0)
	_add_particles(&"dust")


# ---------------------------------------------------------------------------
# Piezas del paisaje
# ---------------------------------------------------------------------------

func _set_lighting(sky_top: Color, horizon: Color, fog: Color, sun: Color, sun_energy: float, sun_rotation: Vector3, fog_enabled: bool = true) -> void:
	_sky_material.sky_top_color = sky_top
	_sky_material.sky_horizon_color = horizon
	_sky_material.ground_horizon_color = fog
	_sky_material.ground_bottom_color = fog.darkened(0.4)
	_sky_material.sky_curve = 0.12
	_environment.ambient_light_color = sky_top.lerp(horizon, 0.5)
	_environment.ambient_light_energy = 0.42
	# Niebla por profundidad: el tablero queda nítido y el paisaje lejano se difumina.
	_environment.fog_enabled = fog_enabled
	_environment.fog_mode = Environment.FOG_MODE_DEPTH
	_environment.fog_light_color = fog
	_environment.fog_density = 0.92
	_environment.fog_depth_begin = 32.0
	_environment.fog_depth_end = 130.0
	_environment.fog_depth_curve = 1.6
	_environment.fog_sky_affect = 0.0
	_sun.light_color = sun
	_sun.light_energy = sun_energy
	_sun.rotation_degrees = sun_rotation


func _make_terrain(config: Dictionary, detail: float = 0.22, cloud_shadows: float = 0.3) -> void:
	_terrain = Terrain.new(config)
	var material := ShaderMaterial.new()
	material.shader = TERRAIN_SHADER
	material.set_shader_parameter(&"detail_strength", detail)
	material.set_shader_parameter(&"cloud_shadow_strength", cloud_shadows)
	var ground := MeshInstance3D.new()
	ground.name = "Terrain"
	ground.mesh = _terrain.build_mesh()
	ground.material_override = material
	_content.add_child(ground)


## Agua a la altura de las lagunas y ríos del terreno. Las aguas turbias
## (roughness alto) reflejan menos el cielo.
func _add_water(deep: Color, shallow: Color, roughness: float = 0.06) -> void:
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	material.set_shader_parameter(&"deep_color", deep)
	material.set_shader_parameter(&"shallow_color", shallow)
	material.set_shader_parameter(&"roughness_value", roughness)
	material.set_shader_parameter(&"specular_amount", 0.7 if roughness < 0.2 else 0.12)
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * Terrain.SIZE
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = plane
	water.material_override = material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.position.y = _terrain.water_level
	_content.add_child(water)


func _add_mist(y: float, tint: Color, density: float, scale: float, inner: float, outer: float, coverage: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = MIST_SHADER
	material.set_shader_parameter(&"tint", tint)
	material.set_shader_parameter(&"density", density)
	material.set_shader_parameter(&"scale", scale)
	material.set_shader_parameter(&"inner_radius", inner)
	material.set_shader_parameter(&"outer_radius", outer)
	material.set_shader_parameter(&"coverage", coverage)
	material.set_shader_parameter(&"drift", Vector2(0.02, 0.008) * (0.05 / scale))
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * outer * 2.0
	var mist := MeshInstance3D.new()
	mist.mesh = plane
	mist.material_override = material
	mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mist.position.y = y
	_content.add_child(mist)


func _add_clouds(tint: Color, density: float) -> void:
	_add_mist(55.0, tint, density, 0.012, 0.0, 330.0, 0.42)


## Pasto con viento (MultiMesh). Más denso cerca del tablero.
func _add_grass(count: int, base: Color, tip: Color, r_min: float, r_max: float, scale: Vector2, rules: Dictionary = {}) -> void:
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var grass_rules := rules.duplicate()
	grass_rules["bias"] = 1.8
	for i in count:
		var spot := _pick_spot(r_min, r_max, grass_rules)
		if spot == Vector3.INF:
			continue
		# Más bajo junto al tablero para no taparlo; crece hacia afuera.
		var near := smoothstep(r_min, r_min + 7.0, Vector2(spot.x, spot.z).length())
		var s := _rng.randf_range(scale.x, scale.y) * lerpf(0.45, 1.0, near)
		transforms.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s * 1.3, s, s * 1.3)), spot + Vector3.DOWN * 0.03))
		var shade := _rng.randf_range(0.82, 1.12)
		colors.append(Color(shade, shade * _rng.randf_range(0.95, 1.05), shade))
	var material := ShaderMaterial.new()
	material.shader = GRASS_SHADER
	material.set_shader_parameter(&"base_color", base)
	material.set_shader_parameter(&"tip_color", tip)
	var instance := _multimesh(_grass_mesh, transforms, colors)
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_content.add_child(instance)


## Flores pequeñas de colores entre el pasto.
func _add_flowers(count: int, palette: Array, r_min: float, r_max: float, rules: Dictionary = {}) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.1
	sphere.radial_segments = 6
	sphere.rings = 3
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for i in count:
		var spot := _pick_spot(r_min, r_max, rules)
		if spot == Vector3.INF:
			continue
		transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * _rng.randf_range(0.7, 1.4)), spot + Vector3.UP * _rng.randf_range(0.12, 0.3)))
		colors.append(palette[_rng.randi() % palette.size()])
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.6
	var instance := _multimesh(sphere, transforms, colors)
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_content.add_child(instance)


## Reparte varias variantes de un modelo (un MultiMesh por variante).
func _scatter_variants(meshes: Array, count: int, r_min: float, r_max: float, scale: Vector2, rules: Dictionary) -> void:
	var per_mesh: Array = []
	for mesh in meshes:
		var list: Array[Transform3D] = []
		per_mesh.append(list)
	for i in count:
		var spot := _pick_spot(r_min, r_max, rules)
		if spot == Vector3.INF:
			continue
		var s := _rng.randf_range(scale.x, scale.y)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * s)
		per_mesh[i % meshes.size()].append(Transform3D(basis, spot + Vector3.DOWN * 0.05))
	for k in meshes.size():
		if not per_mesh[k].is_empty():
			_content.add_child(_multimesh(meshes[k], per_mesh[k]))


## Busca un punto en un anillo alrededor del tablero que cumpla las reglas:
## "tall" (no tapar la vista de la cámara), "avoid" (zonas Vector3(x, z, r)),
## "around" (centro alternativo), "bias" (concentra cerca del radio mínimo).
func _pick_spot(r_min: float, r_max: float, rules: Dictionary) -> Vector3:
	var center: Vector2 = rules.get("around", Vector2.ZERO)
	for attempt in 30:
		var angle := _rng.randf() * TAU
		var r := lerpf(r_min, r_max, pow(_rng.randf(), rules.get("bias", 1.0)))
		var x := center.x + cos(angle) * r
		var z := center.y + sin(angle) * r
		if absf(x) < BOARD_CLEARANCE and absf(z) < BOARD_CLEARANCE:
			continue
		if rules.get("tall", false) and z > 1.5 and absf(x) < 13.0 and x * x + z * z < 22.0 * 22.0:
			continue
		if _terrain.is_water(x, z):
			continue
		var blocked := false
		for zone in rules.get("avoid", []):
			if Vector2(x - zone.x, z - zone.y).length() < zone.z:
				blocked = true
				break
		if blocked:
			continue
		return Vector3(x, _terrain.height(x, z), z)
	return Vector3.INF


func _multimesh(mesh: Mesh, transforms: Array[Transform3D], colors: Array[Color] = []) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = not colors.is_empty()
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
		if not colors.is_empty():
			multimesh.set_instance_color(i, colors[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	return instance


## Partículas ambientales sobre el tablero: neblina, luciérnagas, brasas,
## ceniza o polvo.
func _add_particles(kind: StringName) -> void:
	var particles := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	particles.mesh = quad
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(15.0, 2.5, 15.0)
	particles.position = Vector3(0.0, 2.6, 0.0)
	particles.gravity = Vector3.ZERO
	particles.spread = 180.0
	var color := Color.WHITE
	var additive := false
	match kind:
		&"mist":
			particles.amount = 90
			particles.lifetime = 12.0
			particles.direction = Vector3(1.0, 0.0, 0.3)
			particles.spread = 15.0
			particles.initial_velocity_min = 0.1
			particles.initial_velocity_max = 0.3
			particles.scale_amount_min = 0.2
			particles.scale_amount_max = 0.4
			color = Color(1, 1, 1, 0.16)
		&"fireflies":
			particles.amount = 70
			particles.lifetime = 7.0
			particles.initial_velocity_min = 0.15
			particles.initial_velocity_max = 0.45
			particles.scale_amount_min = 0.12
			particles.scale_amount_max = 0.2
			color = Color("#d8ff6a")
			additive = true
		&"embers":
			particles.amount = 70
			particles.lifetime = 5.0
			particles.direction = Vector3.UP
			particles.spread = 35.0
			particles.gravity = Vector3(0.2, 0.5, 0.0)
			particles.initial_velocity_min = 0.3
			particles.initial_velocity_max = 0.8
			particles.scale_amount_min = 0.08
			particles.scale_amount_max = 0.15
			particles.position.y = 1.0
			color = Color("#ff8a3a")
			additive = true
		&"ash":
			particles.amount = 60
			particles.lifetime = 9.0
			particles.direction = Vector3(1.0, -0.2, 0.0)
			particles.spread = 25.0
			particles.gravity = Vector3(0.0, -0.18, 0.0)
			particles.initial_velocity_min = 0.1
			particles.initial_velocity_max = 0.3
			particles.scale_amount_min = 0.08
			particles.scale_amount_max = 0.15
			color = Color(0.55, 0.52, 0.5, 0.75)
		_:
			particles.amount = 40
			particles.lifetime = 10.0
			particles.initial_velocity_min = 0.03
			particles.initial_velocity_max = 0.1
			particles.scale_amount_min = 0.06
			particles.scale_amount_max = 0.1
			color = Color(1, 1, 1, 0.25)
			additive = true
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color, 0.0))
	ramp.set_color(1, Color(color, 0.0))
	ramp.add_point(0.2, color)
	ramp.add_point(0.8, color)
	if kind == &"fireflies":
		ramp.add_point(0.45, Color(color, color.a * 0.2))
		ramp.add_point(0.6, color)
	particles.color_ramp = ramp
	particles.material_override = Meshes.soft_particle_material(additive)
	particles.preprocess = particles.lifetime
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_content.add_child(particles)


## Columna de humo de un incendio lejano, con fuego en la base.
func _add_smoke(at: Vector3) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var smoke := CPUParticles3D.new()
	smoke.mesh = quad
	smoke.amount = 40
	smoke.lifetime = 11.0
	smoke.preprocess = 11.0
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 1.2
	smoke.direction = Vector3.UP
	smoke.spread = 10.0
	smoke.initial_velocity_min = 1.6
	smoke.initial_velocity_max = 2.6
	smoke.gravity = Vector3(0.35, 0.0, 0.12)
	smoke.scale_amount_min = 2.5
	smoke.scale_amount_max = 4.0
	var curve := Curve.new()
	curve.max_value = 3.0
	curve.add_point(Vector2(0.0, 0.6))
	curve.add_point(Vector2(1.0, 2.6))
	smoke.scale_amount_curve = curve
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.23, 0.21, 0.2, 0.0))
	ramp.set_color(1, Color(0.6, 0.57, 0.54, 0.0))
	ramp.add_point(0.12, Color(0.2, 0.18, 0.17, 0.6))
	ramp.add_point(0.6, Color(0.45, 0.42, 0.4, 0.35))
	smoke.color_ramp = ramp
	smoke.material_override = Meshes.soft_particle_material(false)
	smoke.position = at
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_content.add_child(smoke)

	var fire := CPUParticles3D.new()
	fire.mesh = quad
	fire.amount = 24
	fire.lifetime = 1.2
	fire.preprocess = 1.2
	fire.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fire.emission_sphere_radius = 1.0
	fire.direction = Vector3.UP
	fire.spread = 20.0
	fire.initial_velocity_min = 1.0
	fire.initial_velocity_max = 2.0
	fire.scale_amount_min = 1.0
	fire.scale_amount_max = 1.8
	var fire_ramp := Gradient.new()
	fire_ramp.set_color(0, Color(1.0, 0.75, 0.3, 0.9))
	fire_ramp.set_color(1, Color(1.0, 0.25, 0.05, 0.0))
	fire.color_ramp = fire_ramp
	fire.material_override = Meshes.soft_particle_material(true)
	fire.position = at + Vector3.UP * 0.6
	fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_content.add_child(fire)


func _add_bird(kind: StringName, radius: float, altitude: float, speed: float, phase: float) -> void:
	var bird := Creatures.Bird.new()
	bird.kind = kind
	bird.radius = radius
	bird.altitude = altitude
	bird.speed = speed
	bird.phase = phase
	_content.add_child(bird)
