extends GameAudioRecorder
class_name CompositionRecorder
## Enhanced audio recorder that captures composition metadata
##
## This class extends GameAudioRecorder to capture not just audio,
## but also gameplay events, timing data, and composition metadata.

# Dependencies (will be set from parent)
var beat_manager: Node
var audio_manager: Node
var game_state_manager: Node

# Composition metadata
var composition_metadata: Dictionary = {}
var beat_events: Array = []
var lane_events: Array = []
var layer_info: Array = []
var sound_bank_info: Dictionary = {}

signal beat_recorded(beat_number: int, timestamp: float)
signal lane_change_recorded(lane: int, timestamp: float)
signal composition_saved(data: Dictionary)


func _ready() -> void:
	super._ready()
	
	# Get autoload references
	beat_manager = get_node_or_null("/root/BeatManager")
	audio_manager = get_node_or_null("/root/AudioManager")
	
	# Connect to beat manager
	if beat_manager and beat_manager.has_signal("beat_occurred"):
		beat_manager.beat_occurred.connect(_on_beat_occurred)


func start_composition_recording(track_name: String = "", layers: Array = []) -> void:
	# Capture initial state
	composition_metadata = {
		"track_name": track_name if not track_name.is_empty() else "Untitled Composition",
		"start_time": Time.get_datetime_string_from_system(),
		"bpm": beat_manager.bpm if beat_manager else 120,
		"beats_per_measure": beat_manager.beats_per_measure if beat_manager else 4,
		"audio_settings": _capture_audio_settings(),
		"layer_count": layers.size(),
		"version": "1.0"
	}
	
	# Store layer information
	layer_info = []
	for i in range(layers.size()):
		if layers[i] != null:
			layer_info.append({
				"index": i,
				"has_data": true,
				"sample_count": layers[i].samples.size() if layers[i].has("samples") else 0
			})
	
	# Clear event arrays
	beat_events.clear()
	lane_events.clear()
	
	# Capture current sound bank info
	sound_bank_info = _capture_sound_bank_info()
	
	# Start audio recording
	start_recording()


func stop_composition_recording() -> Dictionary:
	var recording = stop_recording()
	
	if recording:
		composition_metadata["duration"] = recording.get_length()
		composition_metadata["beat_events"] = beat_events
		composition_metadata["lane_events"] = lane_events
		composition_metadata["layer_info"] = layer_info
		composition_metadata["sound_bank_info"] = sound_bank_info
		composition_metadata["end_time"] = Time.get_datetime_string_from_system()
		
		# Calculate statistics
		composition_metadata["stats"] = {
			"total_beats": beat_events.size(),
			"total_lane_changes": lane_events.size(),
			"average_bpm": _calculate_average_bpm()
		}
	
	return {
		"audio": recording,
		"metadata": composition_metadata
	}


func _capture_audio_settings() -> Dictionary:
	var settings = {}
	
	if not audio_manager:
		return settings
	
	# Capture bus volumes
	var buses = ["Master", "Melody", "Bass", "Percussion", "SFX"]
	for bus_name in buses:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx != -1:
			settings[bus_name + "_volume"] = AudioServer.get_bus_volume_db(bus_idx)
			settings[bus_name + "_muted"] = AudioServer.is_bus_mute(bus_idx)
			
			# Capture effect settings
			var effects = []
			for i in range(AudioServer.get_bus_effect_count(bus_idx)):
				var effect = AudioServer.get_bus_effect(bus_idx, i)
				var effect_data = {
					"type": effect.get_class(),
					"enabled": AudioServer.is_bus_effect_enabled(bus_idx, i)
				}
				
				# Capture specific effect parameters
				if effect is AudioEffectReverb:
					effect_data["room_size"] = effect.room_size
					effect_data["damping"] = effect.damping
					effect_data["wet"] = effect.wet
				elif effect is AudioEffectDelay:
					effect_data["dry"] = effect.dry
					effect_data["tap1_delay_ms"] = effect.tap1_delay_ms
					effect_data["tap1_level_db"] = effect.tap1_level_db
				elif effect is AudioEffectChorus:
					effect_data["dry"] = effect.dry
					effect_data["wet"] = effect.wet
					effect_data["voice_count"] = effect.voice_count
				
				effects.append(effect_data)
			
			settings[bus_name + "_effects"] = effects
	
	return settings


func _capture_sound_bank_info() -> Dictionary:
	# This will be populated by the main game when a sound bank is active
	return {
		"bank_name": "Default",
		"bank_index": 0
	}


func _calculate_average_bpm() -> float:
	if beat_events.size() < 2:
		return beat_manager.bpm if beat_manager else 120.0
	
	# Calculate average time between beats
	var total_time = 0.0
	for i in range(1, beat_events.size()):
		total_time += beat_events[i].time - beat_events[i-1].time
	
	var avg_beat_duration = total_time / (beat_events.size() - 1)
	return 60.0 / avg_beat_duration if avg_beat_duration > 0 else 120.0


func _on_beat_occurred(beat_number: int, _beat_time: float) -> void:
	if is_recording:
		var timestamp = get_recording_duration()
		beat_events.append({
			"beat": beat_number,
			"time": timestamp
		})
		beat_recorded.emit(beat_number, timestamp)


func record_lane_change(lane: int) -> void:
	if is_recording:
		var timestamp = get_recording_duration()
		lane_events.append({
			"lane": lane,
			"time": timestamp
		})
		lane_change_recorded.emit(lane, timestamp)


func set_sound_bank_info(bank_name: String, bank_index: int) -> void:
	sound_bank_info = {
		"bank_name": bank_name,
		"bank_index": bank_index,
		"timestamp": Time.get_datetime_string_from_system()
	}


func save_composition(filename: String = "") -> Dictionary:
	if not current_recording:
		push_error("No recording to save!")
		return {}
	
	# Generate filename if not provided
	if filename.is_empty():
		filename = composition_metadata.get("track_name", "Untitled").to_snake_case()
	
	# Save audio file
	var audio_filename = filename + ".wav"
	var audio_path = save_recording(audio_filename)
	
	# Save metadata
	var metadata_path = save_directory + filename + "_metadata.json"
	var file = FileAccess.open(metadata_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(composition_metadata, "\t"))
		file.close()
		print("Saved metadata to: ", metadata_path)
	
	var result = {
		"audio_path": audio_path,
		"metadata_path": metadata_path,
		"composition_name": composition_metadata.get("track_name", "Untitled")
	}
	
	composition_saved.emit(result)
	return result


func export_with_options(options: Dictionary) -> Dictionary:
	# Options can include:
	# - format: "wav" (only WAV supported natively)
	# - quality: "high", "medium", "low"
	# - include_metadata: bool
	# - normalize_audio: bool
	
	if not current_recording:
		push_error("No recording to export!")
		return {}
	
	var export_name = options.get("filename", composition_metadata.get("track_name", "Untitled"))
	var include_metadata = options.get("include_metadata", true)
	
	# For now, we only support WAV export
	# Future versions could shell out to FFmpeg for other formats
	
	var result = {}
	
	# Save audio
	result["audio_path"] = save_recording(export_name + ".wav")
	
	# Save metadata if requested
	if include_metadata:
		var metadata_path = save_directory + export_name + "_metadata.json"
		var file = FileAccess.open(metadata_path, FileAccess.WRITE)
		if file:
			# Add export options to metadata
			var export_metadata = composition_metadata.duplicate()
			export_metadata["export_options"] = options
			export_metadata["export_time"] = Time.get_datetime_string_from_system()
			
			file.store_string(JSON.stringify(export_metadata, "\t"))
			file.close()
			result["metadata_path"] = metadata_path
	
	return result