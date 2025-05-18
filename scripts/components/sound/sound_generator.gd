extends Node
class_name SoundGenerator

# SIGNALS
signal sound_started
signal sound_stopped

# ENUMS
enum WaveType {
	SINE,
	SQUARE,
	TRIANGLE,
	SAW
}

enum Note {
	C, C_SHARP, D, D_SHARP, E, F, F_SHARP, G, G_SHARP, A, A_SHARP, B
}

enum Scale {
	MAJOR,
	MINOR,
	PENTATONIC_MAJOR,
	PENTATONIC_MINOR,
	BLUES,
	CHROMATIC
}

# CONSTANTS
const BASE_OCTAVE = 4 # Middle C octave
const A4_FREQUENCY = 440.0 # A4 = 440Hz (standard tuning)

# Audio settings
var _sample_rate = 44100.0
var _buffer_size = 0.1 # buffer size in seconds

# Sound parameters
var _waveform: WaveType = WaveType.SINE
var _frequency: float = A4_FREQUENCY
var _volume: float = 0.5
var _detune: float = 0.0 # in semitones
var _octave: int = 0 # relative to BASE_OCTAVE
var _is_playing: bool = false
var _current_bus: String = "Melody"

# Working objects
var _player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _phase: float = 0.0

# Scale parameters
var _root_note: Note = Note.C
var _scale_type: Scale = Scale.MAJOR
var _scale_degrees: Array[int] = []

func _init(bus: String = "Melody"):
	_current_bus = bus
	_player = AudioStreamPlayer.new()
	_player.bus = bus
	
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = _sample_rate
	_generator.buffer_length = _buffer_size
	
	_player.stream = _generator
	
	# Calculate scale degrees based on initial scale type
	_update_scale_degrees()

func _ready():
	add_child(_player)
	_player.finished.connect(_on_playback_finished)

func _on_playback_finished():
	_is_playing = false
	emit_signal("sound_stopped")

func start_playback():
	if not _is_playing:
		_player.play()
		_playback = _player.get_stream_playback()
		_is_playing = true
		emit_signal("sound_started")

func stop_playback():
	if _is_playing:
		_player.stop()
		_is_playing = false
		emit_signal("sound_stopped")

func set_bus(bus_name: String):
	_current_bus = bus_name
	_player.bus = bus_name

func get_bus() -> String:
	return _current_bus

func set_waveform(wave_type: WaveType):
	_waveform = wave_type

func get_waveform() -> WaveType:
	return _waveform

func set_frequency(freq: float):
	_frequency = max(20.0, min(20000.0, freq)) # Clamp to audible range

func get_frequency() -> float:
	return _frequency

func set_volume(vol: float):
	_volume = clamp(vol, 0.0, 1.0)

func get_volume() -> float:
	return _volume

func set_detune(semitones: float):
	_detune = semitones

func get_detune() -> float:
	return _detune

func set_octave(rel_octave: int):
	_octave = clamp(rel_octave, -4, 4) # Limit to reasonable range

func get_octave() -> int:
	return _octave

func set_root_note(note: Note):
	_root_note = note
	_update_scale_degrees()

func get_root_note() -> Note:
	return _root_note

func set_scale_type(scale: Scale):
	_scale_type = scale
	_update_scale_degrees()

func get_scale_type() -> Scale:
	return _scale_type

# Sets the note using MIDI note number (60 = C4)
func set_note(midi_note: int):
	var note_freq = midi_to_frequency(midi_note)
	set_frequency(note_freq)

# Takes a scale degree (1-based) and octave and sets the frequency
func set_note_from_scale(scale_degree: int, rel_octave: int = 0):
	var octave_offset = _octave + rel_octave
	
	# Handle scale wrapping
	var octave_change = (scale_degree - 1) / _scale_degrees.size()
	var wrapped_degree = ((scale_degree - 1) % _scale_degrees.size())
	
	# Get the semitone offset from the root note
	var semitone_offset = _scale_degrees[wrapped_degree]
	
	# Calculate the actual note number (relative to C0)
	var note_number = (_root_note + semitone_offset) + (BASE_OCTAVE + octave_offset + octave_change) * 12
	
	# Convert to frequency
	set_note(note_number)

# Generates audio frames based on current settings
func generate_frames(frame_count: int):
	if not _is_playing or _playback == null:
		return
		
	# Calculate the actual frequency with detune
	var actual_freq = _frequency * pow(2, _detune / 12.0)
	
	for i in range(frame_count):
		var sample = _generate_sample(_phase, actual_freq)
		_playback.push_frame(Vector2(sample, sample) * _volume)
		
		# Update phase
		_phase = fmod(_phase + actual_freq / _sample_rate, 1.0)
		
		if i % int(_sample_rate * _buffer_size / 4.0) == 0:
			await get_tree().process_frame

# Generate a single sample based on the waveform type
func _generate_sample(phase: float, freq: float) -> float:
	match _waveform:
		WaveType.SINE:
			return sin(phase * TAU)
			
		WaveType.SQUARE:
			return 1.0 if phase < 0.5 else -1.0
			
		WaveType.TRIANGLE:
			return 1.0 - 4.0 * abs(phase - 0.5) if phase < 1.0 else -1.0
			
		WaveType.SAW:
			return 2.0 * phase - 1.0
			
		_:
			return 0.0

# Updates the scale degrees array based on current scale type
func _update_scale_degrees():
	_scale_degrees.clear()
	
	match _scale_type:
		Scale.MAJOR:
			_scale_degrees = [0, 2, 4, 5, 7, 9, 11]
			
		Scale.MINOR:
			_scale_degrees = [0, 2, 3, 5, 7, 8, 10]
			
		Scale.PENTATONIC_MAJOR:
			_scale_degrees = [0, 2, 4, 7, 9]
			
		Scale.PENTATONIC_MINOR:
			_scale_degrees = [0, 3, 5, 7, 10]
			
		Scale.BLUES:
			_scale_degrees = [0, 3, 5, 6, 7, 10]
			
		Scale.CHROMATIC:
			for i in range(12):
				_scale_degrees.append(i)

# Utility Functions
static func midi_to_frequency(midi_note: int) -> float:
	return 440.0 * pow(2, (midi_note - 69) / 12.0)

static func frequency_to_midi(frequency: float) -> int:
	return round(12 * log(frequency / 440.0) / log(2) + 69)

static func note_name(midi_note: int) -> String:
	var note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var octave = int(midi_note / 12) - 1
	var note = midi_note % 12
	return note_names[note] + str(octave)

# Process method to continuously generate audio
func _process(_delta):
	if _is_playing and _playback != null:
		# Fill the buffer if needed
		if _playback.get_frames_available() > 0:
			generate_frames(_playback.get_frames_available())
