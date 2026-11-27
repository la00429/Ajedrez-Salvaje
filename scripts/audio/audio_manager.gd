class_name AudioManagerService
extends Node
## Administrador global de audio. Los demás módulos solicitan sonidos por nombre
## semántico y no cargan ni manipulan recursos de audio directamente.

const CROSSFADE_SECONDS := 1.0
const MAX_SFX_PLAYERS := 4
const MAX_UI_PLAYERS := 2
const DUPLICATE_COOLDOWN_MSEC := 350
const SILENCE_DB := -60.0

const AUDIO_PATHS := {
	&"ambience_paramo": "res://assets/audio/ambience/paramo/ambience_paramo.mp3",
	&"ambience_amazonia": "res://assets/audio/ambience/amazonia/ambience_amazonia.mp3",
	&"ambience_santuario": "res://assets/audio/ambience/santuario/ambience_santuario.mp3",
	&"event_biome_transition": "res://assets/audio/events/event_biome_transition.mp3",
	&"event_defeat": "res://assets/audio/events/event_defeat.mp3",
	&"event_game_start": "res://assets/audio/events/event_game_start.mp3",
	&"event_king_threatened": "res://assets/audio/events/event_king_threatened.mp3",
	&"event_piece_capture": "res://assets/audio/events/event_piece_capture.mp3",
	&"event_piece_move": "res://assets/audio/events/event_piece_move.mp3",
	&"event_victory": "res://assets/audio/events/event_victory.mp3",
	&"fauna_ecosystem": "res://assets/audio/fauna/fauna_ecosystem.mp3",
	&"fauna_poachers": "res://assets/audio/fauna/amazonia/fauna_poachers.mp3",
	&"fauna_paramo": "res://assets/audio/fauna/paramo/fauna_paramo.mp3",
	&"fauna_santuario": "res://assets/audio/fauna/santuario/fauna_santuario.mp3",
	&"machinery_mining_excavator": "res://assets/audio/machinery/machinery_mining_excavator.mp3",
	&"music_ambient_generic": "res://assets/audio/music/music_ambient_generic.mp3",
	&"music_amazonia": "res://assets/audio/music/amazonia/music_amazonia.mp3",
	&"music_paramo": "res://assets/audio/music/paramo/music_paramo.mp3",
	&"music_santuario": "res://assets/audio/music/santuario/music_santuario.mp3",
	&"simulation_ecological_collapse": "res://assets/audio/simulation/simulation_ecological_collapse.mp3",
	&"simulation_low_water": "res://assets/audio/simulation/simulation_low_water.mp3",
	&"simulation_nursery_regeneration": "res://assets/audio/simulation/simulation_nursery_regeneration.mp3",
	&"ui_click": "res://assets/audio/ui/ui_click.mp3",
	&"ui_confirm": "res://assets/audio/ui/ui_confirm.mp3",
	&"ui_error": "res://assets/audio/ui/ui_error.mp3",
	&"ui_menu_close": "res://assets/audio/ui/ui_menu_close.mp3",
	&"ui_menu_open": "res://assets/audio/ui/ui_menu_open.mp3",
	&"weather_amazon_rain": "res://assets/audio/weather/weather_amazon_rain.mp3",
	&"weather_cold_wind": "res://assets/audio/weather/weather_cold_wind.mp3",
	&"weather_heavy_storm": "res://assets/audio/weather/weather_heavy_storm.mp3",
	&"weather_stream_rain": "res://assets/audio/weather/weather_stream_rain.mp3",
}

const BIOME_AMBIENCE := {
	&"paramo": &"ambience_paramo",
	&"amazonia": &"ambience_amazonia",
	&"santuario": &"ambience_santuario",
}

const BIOME_MUSIC := {
	&"paramo": &"music_paramo",
	&"amazonia": &"music_amazonia",
	&"santuario": &"music_santuario",
	&"clasico": &"music_ambient_generic",
}

const EVENT_SOUNDS := {
	&"biome_transition": &"event_biome_transition",
	&"defeat": &"event_defeat",
	&"game_start": &"event_game_start",
	&"king_threatened": &"event_king_threatened",
	&"piece_capture": &"event_piece_capture",
	&"piece_move": &"event_piece_move",
	&"victory": &"event_victory",
}

const UI_SOUNDS := {
	&"click": &"ui_click",
	&"confirm": &"ui_confirm",
	&"error": &"ui_error",
	&"menu_close": &"ui_menu_close",
	&"menu_open": &"ui_menu_open",
}

const SIMULATION_SOUNDS := {
	&"collapse": &"simulation_ecological_collapse",
	&"low_water": &"simulation_low_water",
	&"regeneration": &"simulation_nursery_regeneration",
}

const FAUNA_SOUNDS := {
	&"paramo": &"fauna_paramo",
	&"amazonia": &"fauna_poachers",
	&"santuario": &"fauna_santuario",
}

var _stream_cache: Dictionary = {}
var _player_tweens: Dictionary = {}
var _last_played_msec: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _channel_players: Dictionary = {}
var _channel_indices: Dictionary = {}
var _channel_paths: Dictionary = {}
var _current_biome: StringName = &""
var _low_water_active := false
var _healthy_fauna_active := false


func _ready() -> void:
	var bus_layout := load("res://audio_bus_layout.tres") as AudioBusLayout
	if bus_layout == null:
		push_error("AudioManager: no se pudo cargar audio_bus_layout.tres")
		return
	AudioServer.set_bus_layout(bus_layout)
	_channel_players = {
		&"music": _make_channel(&"Music", "Music"),
		&"ambience": _make_channel(&"Ambience", "Ambience"),
		&"weather": _make_channel(&"Ambience", "Weather"),
		&"fauna": _make_channel(&"Ambience", "Fauna"),
		&"machinery": _make_channel(&"SFX", "Machinery"),
	}
	for channel in _channel_players:
		_channel_indices[channel] = -1
		_channel_paths[channel] = ""
	for index in MAX_SFX_PLAYERS:
		_sfx_players.append(_new_player(&"SFX", "SFX_%d" % index))
	for index in MAX_UI_PLAYERS:
		_ui_players.append(_new_player(&"UI", "UI_%d" % index))
	_validate_buses()


func set_biome(biome: StringName, play_transition: bool = false) -> void:
	if not BIOME_MUSIC.has(biome):
		push_error("AudioManager: bioma de audio desconocido: %s" % biome)
		return
	var changed := _current_biome != &"" and _current_biome != biome
	_current_biome = biome
	var ambience_key: StringName = BIOME_AMBIENCE.get(biome, &"")
	var music_key: StringName = BIOME_MUSIC[biome]
	_set_loop_channel(&"ambience", _path_for(ambience_key))
	_set_loop_channel(&"music", _path_for(music_key))
	if changed and play_transition:
		play_event(&"biome_transition")


func play_event(event_name: StringName) -> void:
	if not EVENT_SOUNDS.has(event_name):
		push_error("AudioManager: evento de audio desconocido: %s" % event_name)
		return
	_play_one_shot(EVENT_SOUNDS[event_name], &"SFX")


func play_ui(sound_name: StringName = &"click") -> void:
	if not UI_SOUNDS.has(sound_name):
		push_error("AudioManager: sonido de interfaz desconocido: %s" % sound_name)
		return
	_play_one_shot(UI_SOUNDS[sound_name], &"UI")


func play_simulation(sound_name: StringName) -> void:
	if not SIMULATION_SOUNDS.has(sound_name):
		push_error("AudioManager: sonido de simulacion desconocido: %s" % sound_name)
		return
	_play_one_shot(SIMULATION_SOUNDS[sound_name], &"SFX")


func play_fauna_call(biome: StringName) -> void:
	if not FAUNA_SOUNDS.has(biome):
		push_error("AudioManager: bioma de fauna desconocido: %s" % biome)
		return
	_play_one_shot(FAUNA_SOUNDS[biome], &"SFX")


func update_simulation_state(
	biome: StringName,
	climate: StringName,
	water_percent: float,
	mining_active: bool
) -> void:
	var weather_key: StringName = &""
	match climate:
		&"rain":
			weather_key = &"weather_amazon_rain" if biome == &"amazonia" else &"weather_stream_rain"
		&"frost":
			weather_key = &"weather_cold_wind"
		&"catastrophe":
			weather_key = &"weather_heavy_storm"
		&"stable":
			pass
		_:
			push_error("AudioManager: clima de simulacion desconocido: %s" % climate)
			return
	_set_loop_channel(&"weather", _path_for(weather_key))

	var water := clampf(water_percent, 0.0, 100.0)
	if water > 0.0 and water <= 30.0 and not _low_water_active:
		play_simulation(&"low_water")
		_low_water_active = true
	elif water >= 35.0:
		_low_water_active = false

	if water >= 60.0 and not _healthy_fauna_active:
		_set_loop_channel(&"fauna", _path_for(&"fauna_ecosystem"))
		_healthy_fauna_active = true
	elif water < 55.0 and _healthy_fauna_active:
		_set_loop_channel(&"fauna", "")
		_healthy_fauna_active = false

	var machinery_path := _path_for(&"machinery_mining_excavator") if mining_active else ""
	_set_loop_channel(&"machinery", machinery_path)


func stop_simulation_audio() -> void:
	_set_loop_channel(&"weather", "")
	_set_loop_channel(&"fauna", "")
	_set_loop_channel(&"machinery", "")
	_low_water_active = false
	_healthy_fauna_active = false


func stop_music() -> void:
	_set_loop_channel(&"music", "")


func stop_biome_ambience() -> void:
	_set_loop_channel(&"ambience", "")


func stop_all_audio() -> void:
	for channel in _channel_players:
		_set_loop_channel(channel, "")
	stop_simulation_audio()
	stop_music()
	stop_biome_ambience()
	for player in _sfx_players:
		player.stop()
	for player in _ui_players:
		player.stop()
	_current_biome = &""


func set_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_error("AudioManager: no existe el bus %s" % bus_name)
		return
	var volume := clampf(linear_volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))


func get_bus_volume(bus_name: StringName) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_error("AudioManager: no existe el bus %s" % bus_name)
		return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


func set_bus_muted(bus_name: StringName, muted: bool) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_error("AudioManager: no existe el bus %s" % bus_name)
		return
	AudioServer.set_bus_mute(index, muted)


func is_bus_muted(bus_name: StringName) -> bool:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_error("AudioManager: no existe el bus %s" % bus_name)
		return false
	return AudioServer.is_bus_mute(index)


func get_audio_paths() -> Array[String]:
	var paths: Array[String] = []
	for path in AUDIO_PATHS.values():
		paths.append(path)
	paths.sort()
	return paths


func validate_audio_resources() -> Array[String]:
	var missing: Array[String] = []
	for path in get_audio_paths():
		if not ResourceLoader.exists(path):
			missing.append(path)
	return missing


func _make_channel(bus: StringName, label: String) -> Array[AudioStreamPlayer]:
	var players: Array[AudioStreamPlayer] = []
	for index in 2:
		players.append(_new_player(bus, "%s_%d" % [label, index]))
	return players


func _new_player(bus: StringName, player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus
	add_child(player)
	return player


func _validate_buses() -> void:
	for bus_name in [&"Master", &"Music", &"Ambience", &"SFX", &"UI"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			push_error("AudioManager: falta el bus requerido %s" % bus_name)


func _path_for(key: StringName) -> String:
	if key == &"":
		return ""
	if not AUDIO_PATHS.has(key):
		push_error("AudioManager: recurso de audio desconocido: %s" % key)
		return ""
	return AUDIO_PATHS[key]


func _set_loop_channel(channel: StringName, path: String) -> void:
	var players: Array = _channel_players[channel]
	var current_index: int = _channel_indices[channel]
	var current_path: String = _channel_paths[channel]
	if path == current_path and current_index >= 0 and players[current_index].playing:
		return
	if path.is_empty():
		if current_index >= 0:
			_fade_player(players[current_index], SILENCE_DB, CROSSFADE_SECONDS, true)
		_channel_paths[channel] = ""
		_channel_indices[channel] = -1
		return

	var next_index := 0 if current_index < 0 else 1 - current_index
	var next_player: AudioStreamPlayer = players[next_index]
	_cancel_player_tween(next_player)
	next_player.stop()
	var stream := _get_stream(path, true)
	if stream == null:
		return
	next_player.stream = stream
	next_player.volume_db = SILENCE_DB
	next_player.play()
	_fade_player(next_player, 0.0, CROSSFADE_SECONDS, false)
	if current_index >= 0:
		_fade_player(players[current_index], SILENCE_DB, CROSSFADE_SECONDS, true)
	_channel_paths[channel] = path
	_channel_indices[channel] = next_index


func _get_stream(path: String, loop: bool) -> AudioStream:
	var cached: AudioStream = _stream_cache.get(path) as AudioStream
	if cached == null:
		var loaded := ResourceLoader.load(path) as AudioStream
		if loaded == null:
			push_error("AudioManager: no se pudo cargar el recurso %s" % path)
			return null
		_stream_cache[path] = loaded
		cached = loaded
	var stream_copy := cached.duplicate() as AudioStream
	if stream_copy == null:
		push_error("AudioManager: no se pudo duplicar el recurso %s" % path)
		return null
	if stream_copy is AudioStreamMP3:
		(stream_copy as AudioStreamMP3).loop = loop
	return stream_copy


func _play_one_shot(key: StringName, bus: StringName) -> void:
	var path := _path_for(key)
	if path.is_empty():
		return
	var now := Time.get_ticks_msec()
	var last_played: int = _last_played_msec.get(path, -DUPLICATE_COOLDOWN_MSEC)
	if now - last_played < DUPLICATE_COOLDOWN_MSEC:
		return
	var pool: Array[AudioStreamPlayer] = _ui_players if bus == &"UI" else _sfx_players
	for player in pool:
		if player.playing:
			continue
		var stream := _get_stream(path, false)
		if stream == null:
			return
		player.stream = stream
		player.play()
		_last_played_msec[path] = now
		return


func _fade_player(player: AudioStreamPlayer, target_db: float, duration: float, stop_after: bool) -> void:
	_cancel_player_tween(player)
	if duration <= 0.0:
		player.volume_db = target_db
		if stop_after:
			player.stop()
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_db, duration)
	if stop_after:
		tween.tween_callback(player.stop)
	_player_tweens[player.get_instance_id()] = tween


func _cancel_player_tween(player: AudioStreamPlayer) -> void:
	var player_id := player.get_instance_id()
	var tween: Tween = _player_tweens.get(player_id) as Tween
	if tween and tween.is_valid():
		tween.kill()
	_player_tweens.erase(player_id)
