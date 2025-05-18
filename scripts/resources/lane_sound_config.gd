## Lane Sound Configuration Resource
## Stores configuration parameters for a single lane's sound generation.
## Used by LaneSoundSystem to configure individual lane sounds from saved
## resources or presets.

extends Resource
class_name LaneSoundConfig

# Audio properties
@export var waveform: SoundGenerator.WaveType = SoundGenerator.WaveType.SINE
@export var audio_bus: String = "Melody"
@export var octave: int = 0
@export var root_note: SoundGenerator.Note = SoundGenerator.Note.C
@export var volume: float = 0.5
@export var scale_type: SoundGenerator.Scale = SoundGenerator.Scale.MAJOR
@export var scale_degree: int = 1

# Optional effects
@export var detune: float = 0.0
@export var attack_time: float = 0.01
@export var release_time: float = 0.1

# Metadata
@export var config_name: String = "Default Lane Config"
@export var description: String = ""

# Validation
func validate_config() -> bool:
	var is_valid = true
	var errors = []
	
	# Check audio bus exists
	if not AudioServer.get_bus_index(audio_bus) >= 0:
		errors.append("Invalid audio bus: " + audio_bus)
		is_valid = false
	
	# Check volume range
	if volume < 0.0 or volume > 1.0:
		errors.append("Volume must be between 0.0 and 1.0, got: " + str(volume))
		is_valid = false
	
	# Check octave range (reasonable limits)
	if octave < -3 or octave > 3:
		errors.append("Octave must be between -3 and 3, got: " + str(octave))
		is_valid = false
	
	# Check scale degree (assuming max 7 for standard scales)
	if scale_degree < 1 or scale_degree > 7:
		errors.append("Scale degree must be between 1 and 7, got: " + str(scale_degree))
		is_valid = false
	
	# Check detune range
	if detune < -100.0 or detune > 100.0:
		errors.append("Detune must be between -100.0 and 100.0, got: " + str(detune))
		is_valid = false
	
	# Check timing values
	if attack_time < 0.0 or attack_time > 1.0:
		errors.append("Attack time must be between 0.0 and 1.0, got: " + str(attack_time))
		is_valid = false
		
	if release_time < 0.0 or release_time > 1.0:
		errors.append("Release time must be between 0.0 and 1.0, got: " + str(release_time))
		is_valid = false
	
	if not is_valid:
		for error in errors:
			push_error("LaneSoundConfig validation error: " + error)
	
	return is_valid