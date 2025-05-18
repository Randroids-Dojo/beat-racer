extends Node
class_name LaneSoundMapper

# SIGNALS
signal sound_triggered(lane_id: int, lane_type: String)
signal sound_stopped(lane_id: int)

# ENUMS
enum LaneType {
	MELODY,
	BASS,
	PERCUSSION,
	SFX
}

# Lane configuration
var _lanes: Dictionary = {}  # Maps lane_id to LaneConfig
var _active_generators: Dictionary = {}  # Maps lane_id to active SoundGenerator

# Lane configuration class
class LaneConfig:
	var lane_id: int
	var lane_type: LaneType
	var bus_name: String
	var waveform: int
	var base_frequency: float
	var volume: float
	var octave: int
	var note: int
	var scale_type: int
	
	func _init(id: int, type: LaneType, freq: float = 440.0):
		lane_id = id
		lane_type = type
		
		# Set default bus based on lane type
		match lane_type:
			LaneType.MELODY:
				bus_name = AudioManager.MELODY_BUS
				waveform = SoundGenerator.WaveType.SINE
				octave = 0
			LaneType.BASS:
				bus_name = AudioManager.BASS_BUS
				waveform = SoundGenerator.WaveType.SAW
				octave = -1
			LaneType.PERCUSSION:
				bus_name = AudioManager.PERCUSSION_BUS
				waveform = SoundGenerator.WaveType.SQUARE
				octave = 0
			LaneType.SFX:
				bus_name = AudioManager.SFX_BUS
				waveform = SoundGenerator.WaveType.TRIANGLE
				octave = 0
		
		base_frequency = freq
		volume = 0.5
		note = SoundGenerator.Note.C
		scale_type = SoundGenerator.Scale.MAJOR

func _ready():
	pass

# Register a new lane with a specific ID and type
func register_lane(lane_id: int, lane_type: LaneType, base_frequency: float = 440.0) -> bool:
	if _lanes.has(lane_id):
		push_error("Lane ID %d already exists!" % lane_id)
		return false
	
	var config = LaneConfig.new(lane_id, lane_type, base_frequency)
	_lanes[lane_id] = config
	return true

# Update lane configuration
func update_lane_config(lane_id: int, config: Dictionary) -> bool:
	if not _lanes.has(lane_id):
		push_error("Lane ID %d doesn't exist!" % lane_id)
		return false
	
	var lane_config = _lanes[lane_id]
	
	# Update the configuration with values from the dictionary
	if config.has("waveform"):
		lane_config.waveform = config.waveform
	
	if config.has("frequency"):
		lane_config.base_frequency = config.frequency
	
	if config.has("volume"):
		lane_config.volume = config.volume
	
	if config.has("octave"):
		lane_config.octave = config.octave
	
	if config.has("note"):
		lane_config.note = config.note
	
	if config.has("scale_type"):
		lane_config.scale_type = config.scale_type
	
	# Update active generator if it exists
	if _active_generators.has(lane_id):
		apply_config_to_generator(lane_id)
	
	return true

# Get lane bus name
func get_lane_bus(lane_id: int) -> String:
	if _lanes.has(lane_id):
		return _lanes[lane_id].bus_name
	return AudioManager.MASTER_BUS

# Trigger sound on a specific lane
func trigger_sound(lane_id: int) -> bool:
	if not _lanes.has(lane_id):
		push_error("Lane ID %d doesn't exist!" % lane_id)
		return false
	
	var config = _lanes[lane_id]
	
	# Create a new sound generator if one doesn't exist for this lane
	if not _active_generators.has(lane_