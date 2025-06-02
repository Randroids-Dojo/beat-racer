extends Node
class_name GameAudioRecorder
## Base class for recording game audio output
##
## This class provides the foundation for capturing audio during gameplay,
## managing the recording bus setup, and saving recordings as WAV files.

signal recording_started()
signal recording_stopped(recording: AudioStreamWAV)
signal recording_saved(path: String)

# Recording state
var is_recording: bool = false
var record_effect: AudioEffectRecord
var current_recording: AudioStreamWAV
var record_bus_idx: int

# Recording settings
@export var max_recording_duration: float = 300.0  # 5 minutes max
@export var auto_save: bool = false
@export var save_directory: String = "user://recordings/"

var recording_start_time: float = 0.0


func _ready() -> void:
	_setup_recording_bus()
	
	# Ensure save directory exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("recordings"):
		dir.make_dir("recordings")


func _setup_recording_bus() -> void:
	# Check if Record bus already exists
	record_bus_idx = AudioServer.get_bus_index("Record")
	
	if record_bus_idx == -1:
		# Create new recording bus
		AudioServer.add_bus()
		record_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(record_bus_idx, "Record")
		print("Created new Record bus at index: ", record_bus_idx)
	
	# Route all audio buses through the record bus
	_route_buses_for_recording()
	
	# Add record effect if not already present
	var has_record_effect = false
	for i in range(AudioServer.get_bus_effect_count(record_bus_idx)):
		if AudioServer.get_bus_effect(record_bus_idx, i) is AudioEffectRecord:
			record_effect = AudioServer.get_bus_effect(record_bus_idx, i)
			has_record_effect = true
			break
	
	if not has_record_effect:
		record_effect = AudioEffectRecord.new()
		AudioServer.add_bus_effect(record_bus_idx, record_effect)
		print("Added AudioEffectRecord to Record bus")


func _route_buses_for_recording() -> void:
	# Route all game audio buses to the record bus
	var buses_to_route = ["Melody", "Bass", "Percussion", "SFX"]
	
	for bus_name in buses_to_route:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx != -1:
			AudioServer.set_bus_send(bus_idx, "Record")
			print("Routed ", bus_name, " bus to Record bus")
	
	# Ensure Record bus sends to Master
	AudioServer.set_bus_send(record_bus_idx, "Master")


func start_recording() -> void:
	if is_recording:
		push_warning("Already recording!")
		return
	
	if record_effect:
		record_effect.set_recording_active(true)
		is_recording = true
		recording_start_time = Time.get_ticks_msec() / 1000.0
		recording_started.emit()
		print("Recording started at: ", recording_start_time)


func stop_recording() -> AudioStreamWAV:
	if not is_recording:
		push_warning("Not currently recording!")
		return null
	
	if record_effect:
		record_effect.set_recording_active(false)
		is_recording = false
		current_recording = record_effect.get_recording()
		
		if current_recording:
			var duration = current_recording.get_length()
			print("Recording stopped. Duration: ", duration, " seconds")
			recording_stopped.emit(current_recording)
			
			if auto_save:
				var filename = _generate_filename()
				save_recording(filename)
		
		return current_recording
	
	return null


func save_recording(filename: String = "") -> String:
	if not current_recording:
		push_error("No recording to save!")
		return ""
	
	if filename.is_empty():
		filename = _generate_filename()
	
	# Ensure filename has .wav extension
	if not filename.ends_with(".wav"):
		filename += ".wav"
	
	var full_path = save_directory + filename
	current_recording.save_to_wav(full_path)
	
	print("Saved recording to: ", full_path)
	recording_saved.emit(full_path)
	return full_path


func _generate_filename() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "beat_racer_recording_%04d%02d%02d_%02d%02d%02d.wav" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]


func _process(_delta: float) -> void:
	if is_recording:
		var duration = (Time.get_ticks_msec() / 1000.0) - recording_start_time
		if duration >= max_recording_duration:
			print("Max recording duration reached, stopping...")
			stop_recording()


func get_recording_duration() -> float:
	if is_recording:
		return (Time.get_ticks_msec() / 1000.0) - recording_start_time
	elif current_recording:
		return current_recording.get_length()
	return 0.0


func clear_recording() -> void:
	current_recording = null


func get_recording() -> AudioStreamWAV:
	return current_recording


func has_recording() -> bool:
	return current_recording != null


func is_currently_recording() -> bool:
	return is_recording


func reset_recording_bus() -> void:
	# Reset bus routing to default state
	var buses_to_reset = ["Melody", "Bass", "Percussion", "SFX"]
	
	for bus_name in buses_to_reset:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx != -1:
			AudioServer.set_bus_send(bus_idx, "Master")