extends Control

# References to sliders
@onready var master_slider := $VBoxContainer/MasterBus/HSlider
@onready var melody_slider := $VBoxContainer/MelodyBus/HBoxContainer/HSlider
@onready var bass_slider := $VBoxContainer/BassBus/HBoxContainer/HSlider
@onready var percussion_slider := $VBoxContainer/PercussionBus/HBoxContainer/HSlider
@onready var sfx_slider := $VBoxContainer/SFXBus/HBoxContainer/HSlider

# References to test buttons
@onready var melody_test_button := $VBoxContainer/MelodyBus/HBoxContainer/TestButton
@onready var bass_test_button := $VBoxContainer/BassBus/HBoxContainer/TestButton
@onready var percussion_test_button := $VBoxContainer/PercussionBus/HBoxContainer/TestButton
@onready var sfx_test_button := $VBoxContainer/SFXBus/HBoxContainer/TestButton

# Audio test frequencies and parameters
const MELODY_FREQ = 440.0  # A4
const BASS_FREQ = 110.0    # A2
const PERCUSSION_FREQ = 220.0  # A3 (simulated drum hit)
const SFX_FREQ = 880.0     # A5

func _ready():
	# Set initial slider values from AudioManager
	master_slider.value = AudioManager.get_bus_volume_linear(AudioManager.MASTER_BUS)
	melody_slider.value = AudioManager.get_bus_volume_linear(AudioManager.MELODY_BUS)
	bass_slider.value = AudioManager.get_bus_volume_linear(AudioManager.BASS_BUS)
	percussion_slider.value = AudioManager.get_bus_volume_linear(AudioManager.PERCUSSION_BUS)
	sfx_slider.value = AudioManager.get_bus_volume_linear(AudioManager.SFX_BUS)
	
	# Connect slider signals
	master_slider.value_changed.connect(_on_master_slider_changed)
	melody_slider.value_changed.connect(_on_melody_slider_changed)
	bass_slider.value_changed.connect(_on_bass_slider_changed)
	percussion_slider.value_changed.connect(_on_percussion_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	
	# Connect test button signals
	melody_test_button.pressed.connect(_on_melody_test_pressed)
	bass_test_button.pressed.connect(_on_bass_test_pressed)
	percussion_test_button.pressed.connect(_on_percussion_test_pressed)
	sfx_test_button.pressed.connect(_on_sfx_test_pressed)

func _on_master_slider_changed(value: float):
	AudioManager.set_bus_volume_linear(AudioManager.MASTER_BUS, value)

func _on_melody_slider_changed(value: float):
	AudioManager.set_bus_volume_linear(AudioManager.MELODY_BUS, value)

func _on_bass_slider_changed(value: float):
	AudioManager.set_bus_volume_linear(AudioManager.BASS_BUS, value)

func _on_percussion_slider_changed(value: float):
	AudioManager.set_bus_volume_linear(AudioManager.PERCUSSION_BUS, value)

func _on_sfx_slider_changed(value: float):
	AudioManager.set_bus_volume_linear(AudioManager.SFX_BUS, value)

func _on_melody_test_pressed():
	_play_test_sound(AudioManager.MELODY_BUS, MELODY_FREQ, 0.5)

func _on_bass_test_pressed():
	_play_test_sound(AudioManager.BASS_BUS, BASS_FREQ, 0.75)

func _on_percussion_test_pressed():
	_play_percussion_test()

func _on_sfx_test_pressed():
	_play_test_sound(AudioManager.SFX_BUS, SFX_FREQ, 0.25)

func _play_test_sound(bus_name: String, frequency: float, duration: float):
	AudioManager.play_test_tone(bus_name, frequency, duration)

func _play_percussion_test():
	# Create a simple percussive sound
	var player = AudioStreamPlayer.new()
	player.bus = AudioManager.PERCUSSION_BUS
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.1
	
	player.stream = generator
	add_child(player)
	player.play()
	
	var playback = player.get_stream_playback()
	var frames_to_generate = int(0.1 * generator.mix_rate)  # 100ms percussion hit
	
	# Generate a noise burst with envelope
	for i in range(frames_to_generate):
		var envelope = exp(-float(i) / float(frames_to_generate) * 5.0)  # Exponential decay
		var value = (randf() * 2.0 - 1.0) * envelope * 0.7  # White noise with envelope
		playback.push_frame(Vector2(value, value))
		
		if i % int(generator.mix_rate * generator.buffer_length * 0.5) == 0:
			await get_tree().process_frame
	
	await player.finished
	player.queue_free()