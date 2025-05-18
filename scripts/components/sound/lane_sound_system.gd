## Lane Sound System
## Manages sound generation for different track lanes.
## Each lane can have independent sound parameters including waveform,
## musical note, octave, and volume. Supports real-time switching and
## multiple simultaneous playback modes.
##
## Usage:
##   var lane_system = LaneSoundSystem.new()
##   lane_system.set_current_lane(LaneSoundSystem.LaneType.LEFT)
##   lane_system.start_playback()
##
## @tutorial: See tests/gut/unit/test_lane_sound_system.gd for examples

extends Node
class_name LaneSoundSystem

# SIGNALS
signal lane_changed(old_lane: int, new_lane: int)
signal sound_changed(lane: int, generator: SoundGenerator)

# ENUMS
enum LaneType {
	LEFT,
	CENTER,
	RIGHT
}

# CONSTANTS
const MAX_LANES = 3
const DEFAULT_WAVEFORMS = {
	LaneType.LEFT: SoundGenerator.WaveType.SINE,
	LaneType.CENTER: SoundGenerator.WaveType.SQUARE,
	LaneType.RIGHT: SoundGenerator.WaveType.TRIANGLE
}

const DEFAULT_BUSES = {
	LaneType.LEFT: "Melody",
	LaneType.CENTER: "Bass",
	LaneType.RIGHT: "Melody"
}

const DEFAULT_OCTAVES = {
	LaneType.LEFT: 0,
	LaneType.CENTER: -1,
	LaneType.RIGHT: 1
}

const DEFAULT_NOTES = {
	LaneType.LEFT: SoundGenerator.Note.C,
	LaneType.CENTER: SoundGenerator.Note.C,
	LaneType.RIGHT: SoundGenerator.Note.G
}

# Lane configurations
var _lane_configs: Dictionary = {}  # Dictionary[int, Dictionary]
var _lane_generators: Dictionary = {}  # Dictionary[int, SoundGenerator]
var _current_lane: int = LaneType.CENTER
var _is_active: bool = false

# Sound properties
var _base_scale: SoundGenerator.Scale = SoundGenerator.Scale.MAJOR
var _root_note: SoundGenerator.Note = SoundGenerator.Note.C
var _base_volume: float = 0.5
var _bpm: float = 120.0  # Beats per minute for synchronization

func _ready():
	_initialize_lane_configurations()
	_create_sound_generators()

func _initialize_lane_configurations():
	# Initialize default configurations for each lane
	for lane in LaneType.values():
		_lane_configs[lane] = {
			"waveform": DEFAULT_WAVEFORMS.get(lane, SoundGenerator.WaveType.SINE),
			"bus": DEFAULT_BUSES.get(lane, "Melody"),
			"octave": DEFAULT_OCTAVES.get(lane, 0),
			"note": DEFAULT_NOTES.get(lane, SoundGenerator.Note.C),
			"volume": _base_volume,
			"scale": _base_scale,
			"scale_degree": 1
		}

func _create_sound_generators():
	# Create a sound generator for each lane
	for lane in LaneType.values():
		var generator = SoundGenerator.new(_lane_configs[lane]["bus"])
		generator.name = "SoundGenerator_Lane_" + str(lane)
		
		# Configure generator based on lane settings
		_configure_generator(generator, lane)
		
		add_child(generator)
		_lane_generators[lane] = generator

func _configure_generator(generator: SoundGenerator, lane: int):
	var config = _lane_configs[lane]
	
	generator.set_waveform(config["waveform"])
	generator.set_bus(config["bus"])
	generator.set_octave(config["octave"])
	generator.set_root_note(config["note"])
	generator.set_volume(config["volume"])
	generator.set_scale_type(config["scale"])

func set_current_lane(lane: int):
	if lane < 0 or lane >= MAX_LANES:
		push_error("Invalid lane index: " + str(lane))
		return
		
	if lane != _current_lane:
		var old_lane = _current_lane
		_current_lane = lane
		
		# Stop old lane's sound
		if _is_active and _lane_generators.has(old_lane):
			_lane_generators[old_lane].stop_playback()
		
		# Start new lane's sound
		if _is_active and _lane_generators.has(lane):
			_lane_generators[lane].start_playback()
		
		emit_signal("lane_changed", old_lane, lane)

func get_current_lane() -> int:
	return _current_lane

func start_playback():
	if not _is_active:
		_is_active = true
		if _lane_generators.has(_current_lane):
			_lane_generators[_current_lane].start_playback()

func stop_playback():
	if _is_active:
		_is_active = false
		# Stop all active generators
		for generator in _lane_generators.values():
			generator.stop_playback()

func is_playing() -> bool:
	return _is_active

# Lane configuration methods
func set_lane_waveform(lane: int, waveform: SoundGenerator.WaveType):
	if _lane_configs.has(lane):
		_lane_configs[lane]["waveform"] = waveform
		if _lane_generators.has(lane):
			_lane_generators[lane].set_waveform(waveform)

func get_lane_waveform(lane: int) -> SoundGenerator.WaveType:
	if _lane_configs.has(lane):
		return _lane_configs[lane]["waveform"]
	return SoundGenerator.WaveType.SINE

func set_lane_bus(lane: int, bus_name: String):
	if _lane_configs.has(lane):
		_lane_configs[lane]["bus"] = bus_name
		if _lane_generators.has(lane):
			_lane_generators[lane].set_bus(bus_name)

func get_lane_bus(lane: int) -> String:
	if _lane_configs.has(lane):
		return _lane_configs[lane]["bus"]
	return "Melody"

func set_lane_octave(lane: int, octave: int):
	if _lane_configs.has(lane):
		_lane_configs[lane]["octave"] = octave
		if _lane_generators.has(lane):
			_lane_generators[lane].set_octave(octave)

func get_lane_octave(lane: int) -> int:
	if _lane_configs.has(lane):
		return _lane_configs[lane]["octave"]
	return 0

func set_lane_note(lane: int, note: SoundGenerator.Note):
	if _lane_configs.has(lane):
		_lane_configs[lane]["note"] = note
		if _lane_generators.has(lane):
			_lane_generators[lane].set_root_note(note)

func get_lane_note(lane: int) -> SoundGenerator.Note:
	if _lane_configs.has(lane):
		return _lane_configs[lane]["note"]
	return SoundGenerator.Note.C

func set_lane_volume(lane: int, volume: float):
	if _lane_configs.has(lane):
		_lane_configs[lane]["volume"] = volume
		if _lane_generators.has(lane):
			_lane_generators[lane].set_volume(volume)

func get_lane_volume(lane: int) -> float:
	if _lane_configs.has(lane):
		return _lane_configs[lane]["volume"]
	return 0.5

# Global configuration methods
func set_global_scale(scale: SoundGenerator.Scale):
	_base_scale = scale
	for lane in _lane_configs:
		_lane_configs[lane]["scale"] = scale
		if _lane_generators.has(lane):
			_lane_generators[lane].set_scale_type(scale)

func get_global_scale() -> SoundGenerator.Scale:
	return _base_scale

func set_global_root_note(note: SoundGenerator.Note):
	var old_root_note = _root_note
	_root_note = note
	for lane in _lane_configs:
		# Update all lanes to use the new root note
		_lane_configs[lane]["note"] = note
		if _lane_generators.has(lane):
			_lane_generators[lane].set_root_note(note)

func get_global_root_note() -> SoundGenerator.Note:
	return _root_note

func set_global_volume(volume: float):
	_base_volume = volume
	for lane in _lane_configs:
		_lane_configs[lane]["volume"] = volume
		if _lane_generators.has(lane):
			_lane_generators[lane].set_volume(volume)

func get_global_volume() -> float:
	return _base_volume

func set_bpm(bpm: float):
	if bpm <= 0:
		push_error("BPM must be greater than 0")
		return
	_bpm = bpm
	# Future: Notify beat synchronization system

func get_bpm() -> float:
	return _bpm

# Scale degree mapping for lanes
func set_lane_scale_degree(lane: int, degree: int):
	if _lane_configs.has(lane):
		_lane_configs[lane]["scale_degree"] = degree
		if _lane_generators.has(lane):
			_lane_generators[lane].set_note_from_scale(degree, _lane_configs[lane]["octave"])

func get_lane_scale_degree(lane: int) -> int:
	if _lane_configs.has(lane):
		return _lane_configs[lane]["scale_degree"]
	return 1

# Multi-lane playback methods
func start_all_lanes():
	_is_active = true
	for generator in _lane_generators.values():
		generator.start_playback()

func stop_all_lanes():
	_is_active = false
	for generator in _lane_generators.values():
		generator.stop_playback()

func mute_lane(lane: int, muted: bool):
	if _lane_generators.has(lane):
		if muted:
			_lane_generators[lane].set_volume(0.0)
		else:
			_lane_generators[lane].set_volume(_lane_configs[lane]["volume"])

# Debug/test methods
func get_lane_generator(lane: int) -> SoundGenerator:
	if _lane_generators.has(lane):
		return _lane_generators[lane]
	return null

func get_all_generators() -> Array:
	return _lane_generators.values()

func print_lane_configurations():
	print("=== Lane Sound System Configuration ===")
	for lane in _lane_configs:
		var config = _lane_configs[lane]
		print("Lane %d:" % lane)
		print("  Waveform: %s" % str(config["waveform"]))
		print("  Bus: %s" % config["bus"])
		print("  Octave: %d" % config["octave"])
		print("  Note: %s" % str(config["note"]))
		print("  Volume: %.2f" % config["volume"])
		print("  Scale: %s" % str(config["scale"]))
		print("  Scale Degree: %d" % config["scale_degree"])
	print("=====================================")

# Configuration loading from resources
func load_lane_config(lane: int, config_resource: LaneSoundConfig) -> bool:
	if not config_resource:
		push_error("Cannot load null configuration resource")
		return false
		
	if not config_resource.validate_config():
		push_error("Invalid configuration resource for lane " + str(lane))
		return false
	
	if not _lane_configs.has(lane):
		push_error("Invalid lane index: " + str(lane))
		return false
	
	# Apply configuration
	set_lane_waveform(lane, config_resource.waveform)
	set_lane_bus(lane, config_resource.audio_bus)
	set_lane_octave(lane, config_resource.octave)
	set_lane_note(lane, config_resource.root_note)
	set_lane_volume(lane, config_resource.volume)
	_lane_configs[lane]["scale"] = config_resource.scale_type
	_lane_configs[lane]["scale_degree"] = config_resource.scale_degree
	
	# Apply to generator if it exists
	if _lane_generators.has(lane):
		var generator = _lane_generators[lane]
		generator.set_scale_type(config_resource.scale_type)
		generator.set_note_from_scale(config_resource.scale_degree, config_resource.octave)
	
	print("Loaded configuration for lane %d: %s" % [lane, config_resource.config_name])
	return true