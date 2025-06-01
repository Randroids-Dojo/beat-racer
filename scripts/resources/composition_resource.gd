class_name CompositionResource
extends Resource

@export var composition_name: String = "Untitled Composition"
@export var author: String = "Unknown"
@export var creation_date: String = ""
@export var modification_date: String = ""
@export var duration: float = 0.0
@export var bpm: float = 120.0
@export var description: String = ""

@export var layers: Array[LayerData] = []
@export var sound_bank_id: String = "electronic"
@export var track_settings: Dictionary = {}
@export var audio_bus_volumes: Dictionary = {}
@export var audio_effects_enabled: Dictionary = {}
@export var tags: Array[String] = []

@export var metadata: Dictionary = {}

func _init() -> void:
	if creation_date.is_empty():
		creation_date = Time.get_datetime_string_from_system()
	modification_date = creation_date

func add_layer(layer_data: LayerData) -> void:
	layers.append(layer_data)
	modification_date = Time.get_datetime_string_from_system()
	
	var max_time := 0.0
	for sample in layer_data.path_samples:
		if sample.timestamp > max_time:
			max_time = sample.timestamp
	
	if max_time > duration:
		duration = max_time

func remove_layer(index: int) -> void:
	if index >= 0 and index < layers.size():
		layers.remove_at(index)
		modification_date = Time.get_datetime_string_from_system()
		_recalculate_duration()

func clear_layers() -> void:
	layers.clear()
	duration = 0.0
	modification_date = Time.get_datetime_string_from_system()

func get_layer_count() -> int:
	return layers.size()

func _recalculate_duration() -> void:
	duration = 0.0
	for layer in layers:
		for sample in layer.path_samples:
			if sample.timestamp > duration:
				duration = sample.timestamp

func get_formatted_duration() -> String:
	var minutes := int(duration / 60.0)
	var seconds := int(duration) % 60
	return "%02d:%02d" % [minutes, seconds]

func get_file_size_estimate() -> int:
	var size := 0
	for layer in layers:
		size += layer.path_samples.size() * 64
	return size

class LayerData extends Resource:
	@export var layer_name: String = "Layer"
	@export var layer_index: int = 0
	@export var color: Color = Color.WHITE
	@export var volume: float = 1.0
	@export var muted: bool = false
	@export var path_samples: Array[PathSample] = []
	@export var lap_count: int = 1
	@export var recording_date: String = ""
	
	func _init(name: String = "Layer", index: int = 0) -> void:
		layer_name = name
		layer_index = index
		recording_date = Time.get_datetime_string_from_system()

class PathSample extends Resource:
	@export var timestamp: float = 0.0
	@export var position: Vector2 = Vector2.ZERO
	@export var velocity: float = 0.0
	@export var current_lane: int = -1
	@export var beat_aligned: bool = false
	@export var measure_number: int = 0
	@export var beat_in_measure: int = 0
	
	func _init(time: float = 0.0, pos: Vector2 = Vector2.ZERO) -> void:
		timestamp = time
		position = pos