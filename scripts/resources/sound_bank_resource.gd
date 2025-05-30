extends Resource
class_name SoundBankResource

@export var bank_name: String = "Untitled Bank"
@export var description: String = ""
@export var creation_date: String = ""
@export var sound_configs: Array = []

# Structure of sound_configs:
# [
#   {
#     "generator_id": String,        # Unique identifier for this generator
#     "bus_name": String,           # Which audio bus to use
#     "waveform": int,              # SoundGenerator.WaveType enum value
#     "root_note": int,             # SoundGenerator.Note enum value
#     "scale_type": int,            # SoundGenerator.Scale enum value
#     "octave": int,                # Relative octave offset
#     "volume": float,              # Generator volume 0.0-1.0
#     "detune": float,              # Detune in semitones
#     "enabled": bool               # Whether this generator is active
#   }
# ]

# Default sound bank configurations
const DEFAULT_BANKS = {
	"Electronic": {
		"description": "Modern electronic sounds with square waves and pentatonic scales",
		"configs": [
			{
				"generator_id": "melody_lead",
				"bus_name": "Melody",
				"waveform": 1, # SQUARE
				"root_note": 0, # C
				"scale_type": 2, # PENTATONIC_MAJOR
				"octave": 1,
				"volume": 0.7,
				"detune": 0.0,
				"enabled": true
			},
			{
				"generator_id": "bass_line",
				"bus_name": "Bass",
				"waveform": 3, # SAW
				"root_note": 0, # C
				"scale_type": 1, # MINOR
				"octave": -1,
				"volume": 0.8,
				"detune": 0.0,
				"enabled": true
			},
			{
				"generator_id": "percussion_synth",
				"bus_name": "Percussion",
				"waveform": 1, # SQUARE
				"root_note": 0, # C
				"scale_type": 5, # CHROMATIC
				"octave": 2,
				"volume": 0.6,
				"detune": 0.0,
				"enabled": true
			}
		]
	},
	"Ambient": {
		"description": "Soft ambient sounds with sine waves and major scales",
		"configs": [
			{
				"generator_id": "melody_pad",
				"bus_name": "Melody",
				"waveform": 0, # SINE
				"root_note": 9, # A
				"scale_type": 0, # MAJOR
				"octave": 0,
				"volume": 0.5,
				"detune": 0.0,
				"enabled": true
			},
			{
				"generator_id": "bass_pad",
				"bus_name": "Bass",
				"waveform": 0, # SINE
				"root_note": 9, # A
				"scale_type": 0, # MAJOR
				"octave": -2,
				"volume": 0.4,
				"detune": 0.0,
				"enabled": true
			},
			{
				"generator_id": "harmony_pad",
				"bus_name": "Melody",
				"waveform": 2, # TRIANGLE
				"root_note": 9, # A
				"scale_type": 0, # MAJOR
				"octave": 1,
				"volume": 0.3,
				"detune": 5.0, # Slightly detuned for chorus effect
				"enabled": true
			}
		]
	},
	"Orchestral": {
		"description": "Classical orchestral sounds with harmonic scales",
		"configs": [
			{
				"generator_id": "strings_high",
				"bus_name": "Melody",
				"waveform": 2, # TRIANGLE
				"root_note": 3, # D# 
				"scale_type": 0, # MAJOR
				"octave": 1,
				"volume": 0.6,
				"detune": 0.0,
				"enabled": true
			},
			{
				"generator_id": "strings_low",
				"bus_name": "Bass",
				"waveform": 2, # TRIANGLE
				"root_note": 3, # D#
				"scale_type": 0, # MAJOR
				"octave": -1,
				"volume": 0.7,
				"detune": 0.0,
				"enabled": true
			},
			{
				"generator_id": "brass_section",
				"bus_name": "Percussion",
				"waveform": 3, # SAW
				"root_note": 3, # D#
				"scale_type": 0, # MAJOR
				"octave": 0,
				"volume": 0.5,
				"detune": 0.0,
				"enabled": true
			}
		]
	},
	"Blues": {
		"description": "Blues and jazz sounds with blues scales",
		"configs": [
			{
				"generator_id": "blues_lead",
				"bus_name": "Melody",
				"waveform": 3, # SAW
				"root_note": 7, # G
				"scale_type": 4, # BLUES
				"octave": 0,
				"volume": 0.7,
				"detune": 0.0,
				"enabled": true
			},
			{
				"generator_id": "bass_walk",
				"bus_name": "Bass",
				"waveform": 0, # SINE
				"root_note": 7, # G
				"scale_type": 4, # BLUES
				"octave": -2,
				"volume": 0.8,
				"detune": 0.0,
				"enabled": true
			},
			{
				"generator_id": "rhythm_comp",
				"bus_name": "Percussion",
				"waveform": 1, # SQUARE
				"root_note": 7, # G
				"scale_type": 4, # BLUES
				"octave": 1,
				"volume": 0.4,
				"detune": 0.0,
				"enabled": true
			}
		]
	},
	"Minimal": {
		"description": "Minimal techno with simple patterns",
		"configs": [
			{
				"generator_id": "minimal_lead",
				"bus_name": "Melody",
				"waveform": 1, # SQUARE
				"root_note": 0, # C
				"scale_type": 3, # PENTATONIC_MINOR
				"octave": 0,
				"volume": 0.6,
				"detune": 0.0,
				"enabled": true
			},
			{
				"generator_id": "minimal_bass",
				"bus_name": "Bass",
				"waveform": 3, # SAW
				"root_note": 0, # C
				"scale_type": 3, # PENTATONIC_MINOR
				"octave": -1,
				"volume": 0.9,
				"detune": 0.0,
				"enabled": true
			}
		]
	}
}

func _init():
	creation_date = Time.get_datetime_string_from_system()

func save_current_generators(generators: Array):
	"""Save the current state of sound generators to this resource"""
	sound_configs.clear()
	
	for i in range(generators.size()):
		var gen = generators[i]
		if not gen:
			continue
			
		var config = {
			"generator_id": "generator_" + str(i),
			"bus_name": gen.get_bus(),
			"waveform": gen.get_waveform(),
			"root_note": gen.get_root_note(),
			"scale_type": gen.get_scale_type(),
			"octave": gen.get_octave(),
			"volume": gen.get_volume(),
			"detune": gen.get_detune(),
			"enabled": gen._is_playing if "is_playing" in gen else true
		}
		
		sound_configs.append(config)

func apply_to_generators(generators: Array):
	"""Apply this bank's configuration to the provided generators"""
	# Group configurations by bus type
	var bus_configs = {}
	for config in sound_configs:
		var bus = config.get("bus_name", "Melody")
		if not bus in bus_configs:
			bus_configs[bus] = []
		bus_configs[bus].append(config)
	
	# Apply configurations to generators based on their assigned bus
	for i in range(generators.size()):
		var gen = generators[i]
		if not gen:
			continue
			
		var gen_bus = gen.get_bus()
		var config = null
		
		# Find appropriate config for this generator's bus
		if gen_bus in bus_configs and bus_configs[gen_bus].size() > 0:
			# Use round-robin to distribute configs among generators of same bus
			var bus_generator_index = 0
			for j in range(i):
				if j < generators.size() and generators[j] and generators[j].get_bus() == gen_bus:
					bus_generator_index += 1
			
			var config_index = bus_generator_index % bus_configs[gen_bus].size()
			config = bus_configs[gen_bus][config_index]
		else:
			# Use default config for unmatched buses
			config = {
				"bus_name": gen_bus,
				"waveform": 0, # SINE
				"root_note": 0, # C
				"scale_type": 0, # MAJOR
				"octave": 0,
				"volume": 0.5,
				"detune": 0.0
			}
		
		# Apply configuration
		gen.set_bus(config.get("bus_name", gen_bus))
		gen.set_waveform(config.get("waveform", 0))
		gen.set_root_note(config.get("root_note", 0))
		gen.set_scale_type(config.get("scale_type", 0))
		gen.set_octave(config.get("octave", 0))
		gen.set_volume(config.get("volume", 0.5))
		gen.set_detune(config.get("detune", 0.0))
		
		print("SoundBankResource: Applied config to generator %d (bus: %s)" % [i, gen_bus])
		
		# Note: Skip playback control during initialization to avoid audio system issues
		# Playback will be controlled manually by the user/demo

func create_default_bank(default_bank_name: String) -> SoundBankResource:
	"""Create a sound bank from one of the default configurations"""
	if not default_bank_name in DEFAULT_BANKS:
		return null
		
	var bank = SoundBankResource.new()
	var bank_data = DEFAULT_BANKS[default_bank_name]
	
	bank.bank_name = default_bank_name
	bank.description = bank_data["description"]
	bank.sound_configs = bank_data["configs"].duplicate(true)
	
	return bank

func get_generator_count() -> int:
	"""Return the number of generators configured in this bank"""
	return sound_configs.size()

func get_generator_config(index: int) -> Dictionary:
	"""Get configuration for a specific generator by index"""
	if index >= 0 and index < sound_configs.size():
		return sound_configs[index]
	return {}

func set_generator_config(index: int, config: Dictionary):
	"""Set configuration for a specific generator by index"""
	if index >= 0 and index < sound_configs.size():
		sound_configs[index] = config
	elif index == sound_configs.size():
		sound_configs.append(config)

func remove_generator_config(index: int):
	"""Remove a generator configuration by index"""
	if index >= 0 and index < sound_configs.size():
		sound_configs.remove_at(index)

func duplicate_bank() -> SoundBankResource:
	"""Create a copy of this sound bank"""
	var copy = SoundBankResource.new()
	copy.bank_name = bank_name + " (Copy)"
	copy.description = description
	copy.sound_configs = sound_configs.duplicate(true)
	return copy

func get_summary() -> String:
	"""Get a summary description of this sound bank"""
	var summary = "Bank: %s\n" % bank_name
	summary += "Description: %s\n" % description
	summary += "Generators: %d\n" % sound_configs.size()
	
	var buses = {}
	for config in sound_configs:
		var bus = config.get("bus_name", "Unknown")
		buses[bus] = buses.get(bus, 0) + 1
	
	summary += "Bus distribution: "
	for bus in buses:
		summary += "%s(%d) " % [bus, buses[bus]]
	
	return summary.strip_edges()
