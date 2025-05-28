extends Node2D
# Sound Visualization Demo
# Showcases all visual effects that respond to music/sound

signal demo_started()
signal demo_stopped()

# Core systems
@onready var beat_manager = $"/root/BeatManager"
@onready var audio_manager = $"/root/AudioManager"

# Game components
@onready var track_system = $TrackSystem
@onready var lane_sound_system = $LaneSoundSystem
@onready var rhythm_vehicle = $RhythmVehicle
@onready var rhythm_feedback_manager = $RhythmFeedbackManager

# Visual components
@onready var environment_visualizer = $EnvironmentVisualizer
@onready var lane_sound_visualizer = $LaneSoundVisualizer
@onready var beat_pulse_visualizer = $RhythmVehicle/BeatPulseVisualizer
@onready var sound_reactive_trail = $RhythmVehicle/SoundReactiveTrail

# UI
@onready var info_label = $UI/InfoPanel/VBoxContainer/InfoLabel
@onready var controls_label = $UI/InfoPanel/VBoxContainer/ControlsLabel
@onready var bpm_slider = $UI/ControlPanel/VBoxContainer/BPMSlider
@onready var bpm_label = $UI/ControlPanel/VBoxContainer/BPMLabel
@onready var effect_toggles = $UI/ControlPanel/VBoxContainer/EffectToggles

# Demo state
var is_running: bool = false
var current_bpm: int = 120
var active_lanes: Array[bool] = [false, false, false]
var demo_mode: String = "manual"  # manual, auto, music


func _ready():
	print("=== Sound Visualization Demo ===")
	
	# Setup components
	_setup_audio()
	_setup_vehicle()
	_setup_visualizers()
	_setup_ui()
	
	# Connect signals
	_connect_signals()
	
	# Set initial state
	_set_initial_state()
	
	print("Demo ready - Press SPACE to start/stop")
	print("===============================")


func _setup_audio():
	"""Setup audio systems"""
	# Configure BeatManager
	beat_manager.set_bpm(current_bpm)
	
	# Configure lane sounds
	if lane_sound_system:
		lane_sound_system.setup(audio_manager)
		lane_sound_system.add_to_group("lane_sound_system")
		
		# Set interesting sounds for each lane
		var config = lane_sound_system.get_configuration()
		if config:
			# Left lane - Bass
			config.lane_configs[0].waveform = SoundGenerator.Waveform.SINE
			config.lane_configs[0].octave = 2
			config.lane_configs[0].scale_degree = 0
			
			# Center lane - Lead
			config.lane_configs[1].waveform = SoundGenerator.Waveform.SQUARE
			config.lane_configs[1].octave = 4
			config.lane_configs[1].scale_degree = 4
			
			# Right lane - Harmony
			config.lane_configs[2].waveform = SoundGenerator.Waveform.TRIANGLE
			config.lane_configs[2].octave = 3
			config.lane_configs[2].scale_degree = 2


func _setup_vehicle():
	"""Setup vehicle with lane detection"""
	if rhythm_vehicle and track_system:
		rhythm_vehicle.setup(track_system)
		rhythm_vehicle.position = track_system.get_start_position()
		
		# Enable visual feedback
		if rhythm_vehicle.has_method("enable_visual_feedback"):
			rhythm_vehicle.enable_visual_feedback(true)


func _setup_visualizers():
	"""Configure visual components"""
	# Environment visualizer
	if environment_visualizer:
		environment_visualizer.z_index = -10
		environment_visualizer.set_debug_logging(true)
	
	# Lane sound visualizer
	if lane_sound_visualizer:
		lane_sound_visualizer.z_index = -5
		lane_sound_visualizer.lane_sound_system = lane_sound_system
	
	# Beat pulse on vehicle
	if beat_pulse_visualizer:
		beat_pulse_visualizer.set_target_node(rhythm_vehicle)
		beat_pulse_visualizer.enable_debug_logging(true)
	
	# Sound reactive trail
	if sound_reactive_trail:
		sound_reactive_trail.set_debug_logging(true)
	
	# Add rhythm feedback manager to groups
	if rhythm_feedback_manager:
		rhythm_feedback_manager.add_to_group("rhythm_feedback")


func _setup_ui():
	"""Setup UI elements"""
	# Info text
	info_label.text = """Sound Visualization Demo
All visual effects respond to beat and sound"""
	
	controls_label.text = """Controls:
SPACE - Start/Stop
Arrow Keys - Drive vehicle
Q/W/E - Toggle lanes
1-5 - Change demo mode
+/- - Adjust BPM"""
	
	# BPM slider
	bpm_slider.min_value = 60
	bpm_slider.max_value = 240
	bpm_slider.value = current_bpm
	bpm_slider.step = 10
	_update_bpm_label()
	
	# Create effect toggles
	_create_effect_toggles()


func _create_effect_toggles():
	"""Create toggles for each visual effect"""
	var effects = [
		{"name": "Beat Pulse", "node": beat_pulse_visualizer, "property": "auto_pulse_on_beat"},
		{"name": "Lane Visuals", "node": lane_sound_visualizer, "property": "visible"},
		{"name": "Vehicle Trail", "node": sound_reactive_trail, "property": "visible"},
		{"name": "Environment", "node": environment_visualizer, "property": "visible"},
		{"name": "Particles", "node": environment_visualizer, "property": "ambient_particles_enabled"}
	]
	
	for effect in effects:
		var checkbox = CheckBox.new()
		checkbox.text = effect.name
		checkbox.button_pressed = true
		checkbox.toggled.connect(_on_effect_toggled.bind(effect.node, effect.property))
		effect_toggles.add_child(checkbox)


func _connect_signals():
	"""Connect all signals"""
	# BPM control
	bpm_slider.value_changed.connect(_on_bpm_changed)
	
	# Vehicle signals
	if rhythm_vehicle:
		rhythm_vehicle.speed_changed.connect(_on_vehicle_speed_changed)
		rhythm_vehicle.lane_changed.connect(_on_vehicle_lane_changed)
	
	# Beat manager
	beat_manager.beat_occurred.connect(_on_beat_occurred)
	beat_manager.measure_completed.connect(_on_measure_completed)


func _set_initial_state():
	"""Set initial demo state"""
	# Position camera
	var camera = Camera2D.new()
	camera.position = Vector2(512, 300)
	camera.zoom = Vector2(1.2, 1.2)
	camera.make_current()
	add_child(camera)
	
	# Set environment boundaries if track system provides them
	if track_system and track_system.has_method("get_track_points"):
		var boundaries = track_system.get_track_points()
		if boundaries and environment_visualizer:
			environment_visualizer.set_track_boundaries(boundaries)


func _input(event):
	if event.is_action_pressed("ui_select"):  # SPACE
		_toggle_demo()
	
	# Lane toggles
	elif event.is_action_pressed("lane_left"):  # Q
		_toggle_lane(0)
	elif event.is_action_pressed("lane_center"):  # W
		_toggle_lane(1)
	elif event.is_action_pressed("lane_right"):  # E
		_toggle_lane(2)
	
	# Demo modes
	elif event.is_action_pressed("key_1"):
		_set_demo_mode("manual")
	elif event.is_action_pressed("key_2"):
		_set_demo_mode("auto")
	elif event.is_action_pressed("key_3"):
		_set_demo_mode("music")
	elif event.is_action_pressed("key_4"):
		_set_demo_mode("chaos")
	elif event.is_action_pressed("key_5"):
		_set_demo_mode("zen")
	
	# BPM adjustment
	elif event.is_action_pressed("ui_page_up"):  # +
		bpm_slider.value += 10
	elif event.is_action_pressed("ui_page_down"):  # -
		bpm_slider.value -= 10


func _toggle_demo():
	"""Start or stop the demo"""
	is_running = !is_running
	
	if is_running:
		beat_manager.start()
		emit_signal("demo_started")
		print("Demo started")
	else:
		beat_manager.stop()
		_stop_all_sounds()
		emit_signal("demo_stopped")
		print("Demo stopped")


func _toggle_lane(lane: int):
	"""Toggle a lane on/off"""
	if lane < 0 or lane >= active_lanes.size():
		return
	
	active_lanes[lane] = !active_lanes[lane]
	
	if active_lanes[lane]:
		lane_sound_system.play_lane(lane)
		lane_sound_visualizer.activate_lane(lane)
		print("Lane %d activated" % lane)
	else:
		lane_sound_system.stop_lane(lane)
		lane_sound_visualizer.deactivate_lane(lane)
		print("Lane %d deactivated" % lane)


func _set_demo_mode(mode: String):
	"""Change demo mode"""
	demo_mode = mode
	print("Demo mode: %s" % mode)
	
	match mode:
		"manual":
			# User controls everything
			pass
			
		"auto":
			# Automatic lane switching
			_start_auto_mode()
			
		"music":
			# Play a predefined pattern
			_start_music_mode()
			
		"chaos":
			# Random everything
			_start_chaos_mode()
			
		"zen":
			# Calm, slow visuals
			_start_zen_mode()


func _start_auto_mode():
	"""Start automatic demo"""
	# Create timer for lane switching
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(_auto_switch_lanes)
	timer.autostart = true
	add_child(timer)


func _auto_switch_lanes():
	"""Automatically switch active lanes"""
	if not is_running or demo_mode != "auto":
		return
	
	# Random lane activation
	var lane = randi() % 3
	_toggle_lane(lane)


func _start_music_mode():
	"""Start musical pattern mode"""
	# Play a simple pattern
	beat_manager.set_bpm(128)
	
	# Activate lanes in sequence
	_toggle_lane(0)  # Bass always on
	
	# Use beat events to trigger other lanes
	# This would be expanded with actual patterns


func _start_chaos_mode():
	"""Start chaos mode with random effects"""
	beat_manager.set_bpm(180)  # Fast!
	
	# Random BPM changes
	var timer = Timer.new()
	timer.wait_time = 4.0
	timer.timeout.connect(_randomize_bpm)
	timer.autostart = true
	add_child(timer)
	
	# All lanes active
	for i in 3:
		if not active_lanes[i]:
			_toggle_lane(i)


func _start_zen_mode():
	"""Start calm zen mode"""
	beat_manager.set_bpm(60)  # Slow
	
	# Soft visuals
	if environment_visualizer:
		environment_visualizer.particle_base_speed = 10.0
		environment_visualizer.reaction_decay_speed = 0.5
	
	# Single lane, gentle sound
	_stop_all_sounds()
	_toggle_lane(1)


func _randomize_bpm():
	"""Randomize BPM for chaos mode"""
	if demo_mode == "chaos":
		var new_bpm = randi_range(100, 200)
		bpm_slider.value = new_bpm


func _stop_all_sounds():
	"""Stop all lane sounds"""
	for i in 3:
		if active_lanes[i]:
			_toggle_lane(i)


func _on_bpm_changed(value: float):
	"""Handle BPM slider change"""
	current_bpm = int(value)
	beat_manager.set_bpm(current_bpm)
	_update_bpm_label()


func _update_bpm_label():
	"""Update BPM display"""
	bpm_label.text = "BPM: %d" % current_bpm


func _on_effect_toggled(pressed: bool, node: Node, property: String):
	"""Handle effect toggle"""
	if node and property in node:
		node.set(property, pressed)


func _on_vehicle_speed_changed(speed: float):
	"""Handle vehicle speed change"""
	# Could modulate visuals based on speed
	if sound_reactive_trail:
		sound_reactive_trail.set_sound_intensity(speed / 100.0)


func _on_vehicle_lane_changed(from_lane: int, to_lane: int):
	"""Handle vehicle lane change"""
	if sound_reactive_trail:
		sound_reactive_trail.set_current_lane(to_lane)
	
	# Trigger lane sound based on vehicle position
	if is_running and demo_mode == "manual":
		if from_lane >= 0 and from_lane < 3:
			_toggle_lane(from_lane)
		if to_lane >= 0 and to_lane < 3:
			_toggle_lane(to_lane)


func _on_beat_occurred(beat_number: int, beat_time: float):
	"""Handle beat for additional effects"""
	# Could add screen shake or other effects
	pass


func _on_measure_completed(measure_number: int, measure_time: float):
	"""Handle measure completion"""
	# Could trigger special effects every measure
	if demo_mode == "music" and measure_number % 4 == 0:
		# Pattern change every 4 measures
		pass


func _process(_delta):
	"""Update demo state"""
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()