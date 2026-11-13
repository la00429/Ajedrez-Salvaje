extends Node3D
## Efecto visual breve en 3D: partículas que saltan y una onda en el suelo.
##
## El [Board] lo crea al retirar una pieza (captura, tala) o al bloquear una
## casilla (catástrofe). Se libera solo cuando termina.

var color := Color.WHITE
## Tamaño de referencia (normalmente media casilla).
var radius := 0.5
var duration := 0.8


func _ready() -> void:
	_spawn_particles()
	_spawn_ring()
	var timer := get_tree().create_timer(duration + 0.3, false)
	timer.timeout.connect(queue_free)


func _spawn_particles() -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.amount = 22
	particles.lifetime = duration
	particles.explosiveness = 0.95
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = radius * 0.25
	particles.direction = Vector3.UP
	particles.spread = 65.0
	particles.initial_velocity_min = radius * 2.0
	particles.initial_velocity_max = radius * 4.0
	particles.gravity = Vector3.DOWN * radius * 14.0
	particles.damping_min = radius * 1.5
	particles.damping_max = radius * 3.0
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.2

	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = curve

	var mesh := SphereMesh.new()
	mesh.radius = radius * 0.07
	mesh.height = radius * 0.14
	mesh.radial_segments = 8
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.4
	mesh.material = material
	particles.mesh = mesh
	add_child(particles)
	particles.emitting = true


func _spawn_ring() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.86
	torus.outer_radius = radius
	torus.rings = 32
	torus.ring_segments = 6
	ring.mesh = torus
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.scale = Vector3(0.3, 0.05, 0.3)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color, 0.8)
	ring.material_override = material
	add_child(ring)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(1.3, 0.05, 1.3), duration * 0.7) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, duration * 0.7)
