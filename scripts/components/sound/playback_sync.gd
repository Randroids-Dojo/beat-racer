extends Node
class_name PlaybackSync

# Playback Synchronization System
# Coordinates audio playback with the beat manager for perfect timing
# Handles sync between multiple audio sources and beat events

signal sync_started()
signal sync_stopped()
signal desync_detected(offset: float)
signal sync_corrected()
signal metronome_tick(beat: int, is_downbeat: bool)

# Sync properties
var _is_synced: bool = false
var _sync_tolerance: float = 0.05  # 50ms tolerance
var _last_sync_check: float = 0.0
var _sync_check_interval: float = 0.5  # Check sync every 500ms
var _desync_count: int = 0
var _max_desync_before_correction: int = 3

# Audio players
var _music_players: Dictionary = {}  # Dictionary[String, AudioStreamPlayer]
var _current_music_player: AudioStreamPlayer = null
var _fade_duration: float = 0.5

# Metronome
var _metronome_enabled: bool = false
var _metronome_volume: float = -6.0  # dB
var _metronome_generator: Node  # MetronomeGenerator

# References
var _beat_manager: Node = null
var _audio_manager: Node = null

# Debug
var _debug_logging: bool = true

func _ready():
	_log("=== PlaybackSync Initialization ===")
	
	# Add to group for easy discovery
	add_to_group("playback_sync")
	
	# Get references to autoloaded singletons
	_beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	_audio_manager = get_node("/root/AudioManager") if has_node("/root/AudioManager") else null
	
	if not _beat_manager:
		push_error("BeatManager not found! PlaybackSync requires BeatManager to function.")
		return
		
	if not _audio_manager:
		push_warning("AudioManager not found. Some features may be limited.")
	
	_setup_metronome()
	_connect_signals()
	
	_log("PlaybackSync initialized")
	_log("================================")

func _log(message: String) -> void:
	if _debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] PlaybackSync: %s" % [timestamp, message])

func _setup_metronome():
	# Create simple metronome
	var MetronomeClass = preload("res://scripts/components/sound/metronome_simple.gd")
	_metronome_generator = MetronomeClass.new()
	add_child(_metronome_generator)
	
	_log("Metronome setup complete")

func _connect_signals():
	if _beat_manager:
		_beat_manager.connect("beat_occurred", _on_beat_occurred)
		_beat_manager.connect("measure_completed", _on_measure_completed)
		_log("Connected to BeatManager signals")

# [Function removed - now using MetronomeGenerator]

func start_sync():
	if not _beat_manager:
		push_error("Cannot start sync without BeatManager")
		return
		
	_is_synced = true
	_desync_count = 0
	_last_sync_check = 0.0
	
	emit_signal("sync_started")
	_log("Synchronization started")

func stop_sync():
	_is_synced = false
	stop_all_music()
	
	emit_signal("sync_stopped")
	_log("Synchronization stopped")

func _process(delta: float):
	if not _is_synced:
		return
		
	_last_sync_check += delta
	
	# Periodic sync checking
	if _last_sync_check >= _sync_check_interval:
		_check_sync()
		_last_sync_check = 0.0

func _check_sync():
	if not _current_music_player or not _current_music_player.playing:
		return
		
	# Calculate expected playback position based on beats
	var expected_position = _beat_manager.get_total_beats() * _beat_manager.beat_duration
	var actual_position = _current_music_player.get_playback_position()
	var offset = abs(expected_position - actual_position)
	
	if offset > _sync_tolerance:
		_desync_count += 1
		emit_signal("desync_detected", offset)
		_log("Desync detected: %.3fs offset" % offset)
		
		if _desync_count >= _max_desync_before_correction:
			_correct_sync()
	else:
		_desync_count = 0

func _correct_sync():
	if not _current_music_player:
		return
		
	var expected_position = _beat_manager.get_total_beats() * _beat_manager.beat_duration
	_current_music_player.seek(expected_position)
	_desync_count = 0
	
	emit_signal("sync_corrected")
	_log("Sync corrected")

func _on_beat_occurred(beat_number: int, beat_time: float):
	if _metronome_enabled:
		var is_downbeat = (beat_number % _beat_manager.beats_per_measure) == 0
		_play_metronome_tick(is_downbeat)
		emit_signal("metronome_tick", beat_number, is_downbeat)

func _on_measure_completed(measure_number: int, measure_time: float):
	# Could trigger special effects or transitions on measure boundaries
	pass

func _play_metronome_tick(is_downbeat: bool):
	if not _metronome_generator:
		return
		
	_metronome_generator.play_metronome_beat(is_downbeat, _metronome_volume)

# Music player management
func add_music_track(name: String, stream: AudioStream) -> bool:
	if _music_players.has(name):
		_log("Music track '%s' already exists" % name)
		return false
		
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Melody"  # Use melody bus for music
	player.autoplay = false
	add_child(player)
	
	_music_players[name] = player
	_log("Added music track: %s" % name)
	return true

func play_music_track(name: String, fade_in: bool = true):
	if not _music_players.has(name):
		push_error("Music track '%s' not found" % name)
		return
		
	var new_player = _music_players[name]
	
	# Fade out current track if playing
	if _current_music_player and _current_music_player.playing and fade_in:
		_fade_out_player(_current_music_player)
	
	# Start new track
	_current_music_player = new_player
	
	if fade_in:
		_fade_in_player(new_player)
	else:
		new_player.volume_db = 0.0
		new_player.play()
	
	_log("Playing music track: %s" % name)

func stop_all_music(fade_out: bool = true):
	for player in _music_players.values():
		if player.playing:
			if fade_out:
				_fade_out_player(player)
			else:
				player.stop()

func _fade_in_player(player: AudioStreamPlayer):
	player.volume_db = -40.0
	player.play()
	
	var tween = create_tween()
	tween.tween_property(player, "volume_db", 0.0, _fade_duration)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

func _fade_out_player(player: AudioStreamPlayer):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -40.0, _fade_duration)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.finished.connect(func(): player.stop())

# Metronome control
func set_metronome_enabled(enabled: bool):
	_metronome_enabled = enabled
	_log("Metronome %s" % ("enabled" if enabled else "disabled"))

func is_metronome_enabled() -> bool:
	return _metronome_enabled

func set_metronome_volume(volume_db: float):
	_metronome_volume = volume_db

func get_metronome_volume() -> float:
	return _metronome_volume

# Sync state queries
func is_synced() -> bool:
	return _is_synced

func get_sync_accuracy() -> float:
	if _desync_count == 0:
		return 100.0
	return max(0.0, 100.0 - (_desync_count * 10.0))

func get_current_music_track() -> String:
	if not _current_music_player:
		return ""
		
	for name in _music_players:
		if _music_players[name] == _current_music_player:
			return name
	
	return ""

# Utility methods
func sync_to_beat():
	# Immediately sync current playback to the beat
	if _current_music_player and _current_music_player.playing:
		_correct_sync()

func set_sync_tolerance(tolerance_ms: float):
	_sync_tolerance = tolerance_ms / 1000.0
	_log("Sync tolerance set to: %.1fms" % tolerance_ms)

# Debug methods
func print_debug_info():
	print("=== PlaybackSync Debug Info ===")
	print("Is Synced: %s" % str(_is_synced))
	print("Sync Accuracy: %.1f%%" % get_sync_accuracy())
	print("Desync Count: %d" % _desync_count)
	print("Current Track: %s" % get_current_music_track())
	print("Metronome Enabled: %s" % str(_metronome_enabled))
	print("Music Players: %d" % _music_players.size())
	print("==============================")