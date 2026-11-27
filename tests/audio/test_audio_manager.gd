extends SceneTree
## Pruebas del Autoload de audio.
## Ejecutar: godot --headless --path . --script res://tests/audio/test_audio_manager.gd

var _checks := 0
var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("  FALLA: " + message)


func _run() -> void:
	await process_frame
	var manager := root.get_node_or_null("AudioManager") as AudioManagerService
	_check(manager != null, "AudioManager está registrado como Autoload")
	if manager == null:
		quit(1)
		return

	print("- Buses y recursos")
	for bus in [&"Master", &"Music", &"Ambience", &"SFX", &"UI"]:
		_check(AudioServer.get_bus_index(bus) >= 0, "existe el bus %s" % bus)
	var paths: Array[String] = manager.get_audio_paths()
	_check(paths.size() == 31, "el catálogo contiene los 31 archivos de audio")
	for path in paths:
		_check(ResourceLoader.exists(path), "existe el recurso %s" % path)
		_check(ResourceLoader.load(path) is AudioStream, "Godot carga %s como AudioStream" % path)
	_check(manager.validate_audio_resources().is_empty(), "no hay rutas de audio inexistentes")

	print("- Biomas y estados de simulación")
	manager.set_biome(&"paramo")
	_check(manager._channel_paths[&"music"] == manager.AUDIO_PATHS[&"music_paramo"], "selecciona música del páramo")
	manager.set_biome(&"clasico")
	_check(manager._channel_paths[&"music"] == manager.AUDIO_PATHS[&"music_ambient_generic"], "el modo clásico usa música genérica")
	_check(manager._channel_paths[&"ambience"] == "", "el modo clásico no asigna ambiente inexistente")
	manager.update_simulation_state(&"amazonia", &"rain", 70.0, false)
	_check(manager._channel_paths[&"weather"] == manager.AUDIO_PATHS[&"weather_amazon_rain"], "la lluvia amazónica activa su ambiente")
	var weather_index: int = manager._channel_indices[&"weather"]
	manager.update_simulation_state(&"amazonia", &"rain", 70.0, false)
	_check(manager._channel_indices[&"weather"] == weather_index, "el clima repetido no reinicia la pista")
	manager.update_simulation_state(&"paramo", &"frost", 70.0, false)
	_check(manager._channel_paths[&"weather"] == manager.AUDIO_PATHS[&"weather_cold_wind"], "la helada activa viento frío")
	manager.update_simulation_state(&"paramo", &"stable", 0.0, false)
	_check(not manager._low_water_active, "el colapso hídrico no duplica el aviso de agua baja")
	manager.update_simulation_state(&"paramo", &"stable", 29.0, true)
	_check(manager._channel_paths[&"weather"] == "", "el clima estable detiene la capa meteorológica")
	_check(manager._low_water_active, "el agua baja activa su estado una sola vez")
	_check(manager._channel_paths[&"machinery"] == manager.AUDIO_PATHS[&"machinery_mining_excavator"], "la retroexcavadora activa maquinaria")
	manager.update_simulation_state(&"paramo", &"stable", 25.0, false)
	_check(manager._low_water_active, "el estado de agua baja no se repite por actualización")
	_check(manager._channel_paths[&"machinery"] == "", "la maquinaria se detiene al quedar inactiva")
	manager.update_simulation_state(&"paramo", &"stable", 60.0, false)
	_check(manager._channel_paths[&"fauna"] == manager.AUDIO_PATHS[&"fauna_ecosystem"], "la fauna se activa con agua suficiente")
	manager.update_simulation_state(&"paramo", &"stable", 54.0, false)
	_check(manager._channel_paths[&"fauna"] == "", "la fauna se atenúa al entrar en estrés")
	_check(not manager._low_water_active, "el aviso de agua baja se rearma al recuperarse")
	manager.stop_simulation_audio()

	print("- Volumen y mute")
	var original_volume: float = manager.get_bus_volume(&"Music")
	var original_mute: bool = manager.is_bus_muted(&"Music")
	manager.set_bus_volume(&"Music", 0.37)
	_check(is_equal_approx(manager.get_bus_volume(&"Music"), 0.37), "ajusta el volumen lineal del bus")
	manager.set_bus_volume(&"Music", 5.0)
	_check(manager.get_bus_volume(&"Music") <= 1.0, "limita el volumen al rango permitido")
	manager.set_bus_muted(&"Music", not original_mute)
	_check(manager.is_bus_muted(&"Music") != original_mute, "cambia el mute del bus")
	manager.set_bus_volume(&"Music", original_volume)
	manager.set_bus_muted(&"Music", original_mute)

	print("\n%d comprobaciones, %d fallidas" % [_checks, _failures])
	manager.stop_all_audio()
	await create_timer(1.1).timeout
	quit(1 if _failures > 0 else 0)
