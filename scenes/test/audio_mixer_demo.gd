extends Node2D

# Audio mixer control demo scene
# This scene demonstrates the audio mixing controls from Story 014

const AudioMixerPanel = preload("res://scripts/components/ui/audio_mixer_panel.gd")
const LaneSoundSystem = preload("res://scripts/components/sound/lane_sound_system.gd")

var mixer_panel: AudioMixerPanel
var lane_sound_system: LaneSoundSystem
var test_players: Dictionary = {}
var is_playing: bool = false

func _ready():
	print("=== Audio Mixer Demo Starting ===")
	_setup_ui()
	_setup_lane_sounds()
	_create_test_tone_buttons()
	_add_instructions()
	print("Demo ready - Use test buttons to play sounds through different buses")

func _setup_ui():
	# Create main container
	var screen_size = get_viewport().size
	var main_container = VBoxContainer.new()
	main_container.position = Vector2(20, 20)
	main_container.add_theme_constant_override("separation", 20)
	add_child(main_container)
	
	# Title
	var title = Label.new()
	title.text = "Audio Mixer Control Demo"
	title.add_theme_font_size_override("font_size", 32)
	main_container.add_child(title)
	
	# Create mixer panel
	mixer_panel = AudioMixerPanel.new()
	mixer_panel.name = "MixerPanel"
	main_container.add_child(mixer_panel)
	
	# Connect signals
	mixer_panel.volume_changed.connect(_on_volume_changed)
	mixer_panel.mute_changed.connect(_on_mute_changed)
	mixer_panel.solo_changed.connect(_on_solo_changed)
	mixer_panel.effect_toggled.connect(_on_effect_toggled)
	mixer_panel.effect_parameter_changed.connect(_on_effect_parameter_changed)

func _setup_lane_sounds():
	# Create lane sound system for testing
	lane_sound_system = LaneSoundSystem.new()
	lane_sound_system.name = "LaneSoundSystem"
	add_child(lane_sound_system)
	
	# Configure sounds for each lane (bus)
	lane_sound_system.set_lane_config(LaneSoundSystem.Lane.LEFT, {
		"waveform": LaneSoundSystem.Waveform.SINE,
		"bus": "Melody",
		"volume": 0.5,
		"octave": 4,
		"scale_degree": 0
	})
	
	lane_sound_system.set_lane_config(LaneSoundSystem.Lane.CENTER, {
		"waveform": LaneSoundSystem.Waveform.SQUARE,
		"bus": "Bass",
		"volume": 0.4,
		"octave": 2,
		"scale_degree": 0
	})
	
	lane_sound_system.set_lane_config(LaneSoundSystem.Lane.RIGHT, {
		"waveform": LaneSoundSystem.Waveform.TRIANGLE,
		"bus": "Percussion",
		"volume": 0.3,
		"octave": 3,
		"scale_degree": 4
	})

func _create_test_tone_buttons():
	# Create test tone buttons container
	var button_container = HBoxContainer.new()
	button_container.position = Vector2(20, 650)
	button_container.add_theme_constant_override("separation", 10)
	add_child(button_container)
	
	# Label
	var label = Label.new()
	label.text = "Test Tones:"
	label.add_theme_font_size_override("font_size", 18)
	button_container.add_child(label)
	
	# Create test buttons for each bus
	var buses = ["Melody", "Bass", "Percussion", "SFX"]
	for bus in buses:
		var button = Button.new()
		button.text = "Test " + bus
		button.custom_minimum_size = Vector2(120, 40)
		button.pressed.connect(_play_test_tone.bind(bus))
		button_container.add_child(button)
	
	# Lane sound buttons
	button_container.add_child(VSeparator.new())
	
	var lane_label = Label.new()
	lane_label.text = "Lane Sounds:"
	lane_label.add_theme_font_size_override("font_size", 18)
	button_container.add_child(lane_label)
	
	var play_button = Button.new()
	play_button.text = "Play All Lanes"
	play_button.custom_minimum_size = Vector2(120, 40)
	play_button.toggle_mode = true
	play_button.toggled.connect(_on_play_toggled)
	button_container.add_child(play_button)
	
	# Individual lane buttons
	var lanes = ["Left", "Center", "Right"]
	for i in range(lanes.size()):
		var lane_button = Button.new()
		lane_button.text = lanes[i]
		lane_button.custom_minimum_size = Vector2(80, 40)
		lane_button.toggle_mode = true
		lane_button.toggled.connect(_on_lane_toggled.bind(i))
		button_container.add_child(lane_button)

func _add_instructions():
	# Add instruction text
	var instructions = RichTextLabel.new()
	instructions.position = Vector2(20, 720)
	instructions.custom_minimum_size = Vector2(900, 100)
	instructions.bbcode_enabled = true
	instructions.text = "[b]Instructions:[/b]\n" + \
		"• Adjust volume sliders to control bus volumes\n" + \
		"• Use M/S buttons for Mute/Solo functionality\n" + \
		"• Click ⚙ to edit effect parameters\n" + \
		"• Test buttons play sounds through specific buses\n" + \
		"• Use Presets tab to save/load mixer settings\n" + \
		"• ESC to exit demo"
	add_child(instructions)

func _play_test_tone(bus_name: String):
	# Play a test tone on the specified bus
	print("Playing test tone on bus: " + bus_name)
	
	# Stop existing test tone for this bus
	if bus_name in test_players:
		test_players[bus_name].queue_free()
		test_players.erase(bus_name)
	
	# Create new test tone
	var player = AudioStreamPlayer.new()
	player.bus = bus_name
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.1
	
	player.stream = generator
	add_child(player)
	player.play()
	
	test_players[bus_name] = player
	
	# Generate tone
	var playback = player.get_stream_playback()
	if playback:
		var frequency = _get_bus_frequency(bus_name)
		var duration = 1.0
		var frames = int(duration * generator.mix_rate)
		var phase = 0.0
		
		for i in frames:
			var value = sin(phase * TAU) * 0.3
			playback.push_frame(Vector2(value, value))
			phase = fmod(phase + frequency / generator.mix_rate, 1.0)
		
		# Auto-remove after duration
		await get_tree().create_timer(duration).timeout
		if is_instance_valid(player):
			player.queue_free()
			test_players.erase(bus_name)

func _get_bus_frequency(bus_name: String) -> float:
	# Get appropriate frequency for each bus type
	match bus_name:
		"Melody": return 440.0  # A4
		"Bass": return 110.0    # A2
		"Percussion": return 220.0  # A3
		"SFX": return 880.0     # A5
		_: return 440.0

func _on_play_toggled(pressed: bool):
	is_playing = pressed
	if pressed:
		lane_sound_system.start_all_lanes()
		print("Started all lane sounds")
	else:
		lane_sound_system.stop_all_lanes()
		print("Stopped all lane sounds")

func _on_lane_toggled(pressed: bool, lane_idx: int):
	if pressed:
		lane_sound_system.start_lane(lane_idx)
		print("Started lane %d" % lane_idx)
	else:
		lane_sound_system.stop_lane(lane_idx)
		print("Stopped lane %d" % lane_idx)

func _on_volume_changed(bus_name: String, volume_db: float):
	print("Volume changed - Bus: %s, Volume: %.1f dB" % [bus_name, volume_db])

func _on_mute_changed(bus_name: String, muted: bool):
	print("Mute changed - Bus: %s, Muted: %s" % [bus_name, str(muted)])

func _on_solo_changed(bus_name: String, soloed: bool):
	print("Solo changed - Bus: %s, Soloed: %s" % [bus_name, str(soloed)])

func _on_effect_toggled(bus_name: String, effect_idx: int, enabled: bool):
	print("Effect toggled - Bus: %s, Effect: %d, Enabled: %s" % [bus_name, effect_idx, str(enabled)])

func _on_effect_parameter_changed(bus_name: String, effect_idx: int, param_name: String, value: float):
	print("Effect parameter changed - Bus: %s, Effect: %d, Param: %s, Value: %.2f" % [bus_name, effect_idx, param_name, value])

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		# Stop all sounds
		lane_sound_system.stop_all_lanes()
		for player in test_players.values():
			if is_instance_valid(player):
				player.queue_free()
		test_players.clear()
		
		# Return to main
		get_tree().quit()