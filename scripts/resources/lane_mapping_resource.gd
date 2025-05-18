extends Resource
class_name LaneMappingResource

# Lane configurations
@export var left_lane_config: LaneSoundConfig
@export var center_lane_config: LaneSoundConfig
@export var right_lane_config: LaneSoundConfig

# Global settings
@export var base_bpm: float = 120.0
@export var global_scale: SoundGenerator.Scale = SoundGenerator.Scale.MAJOR
@export var global_root_note: SoundGenerator.Note = SoundGenerator.Note.C
@export var mapping_name: String = "Default Mapping"

func _init():
	# Create default configurations if not set
	if not left_lane_config:
		left_lane_config = LaneSoundConfig.new()
		left_lane_config.waveform = SoundGenerator.WaveType.SINE
		left_lane_config.audio_bus = "Melody"
		left_lane_config.octave = 0
		left_lane_config.scale_degree = 1
	
	if not center_lane_config:
		center_lane_config = LaneSoundConfig.new()
		center_lane_config.waveform = SoundGenerator.WaveType.SQUARE
		center_lane_config.audio_bus = "Bass"
		center_lane_config.octave = -1
		center_lane_config.scale_degree = 1
		
	if not right_lane_config:
		right_lane_config = LaneSoundConfig.new()
		right_lane_config.waveform = SoundGenerator.WaveType.TRIANGLE
		right_lane_config.audio_bus = "Melody"
		right_lane_config.octave = 1
		right_lane_config.scale_degree = 5  # Fifth degree (dominant)