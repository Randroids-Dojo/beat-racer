extends Node2D

## Demo scene for testing camera system functionality

@onready var track_system: TrackSystem = $TrackSystem
@onready var camera: Camera2D = $CameraController
@onready var screen_shake: Node = $ScreenShakeSystem
@onready var ui_container: Control = $CanvasLayer/UIContainer

# Vehicles
var vehicle1: EnhancedVehicle
var vehicle2: EnhancedVehicle
var current_vehicle_index: int = 0
var vehicles: Array[EnhancedVehicle] = []

# UI References
var mode_label: Label
var target_label: Label
var zoom_label: Label
var speed_label: Label
var shake_intensity_label: Label

func _ready() -> void:
	# Set up camera and shake system
	screen_shake.camera = camera
	
	# Create vehicles
	_create_vehicles()
	
	# Create UI
	_create_ui()
	
	# Start with first vehicle
	camera.set_follow_mode(vehicle1)
	
	# Connect to camera signals
	camera.camera_mode_changed.connect(_on_camera_mode_changed)
	camera.target_changed.connect(_on_target_changed)
	camera.transition_started.connect(_on_transition_started)
	camera.transition_completed.connect(_on_transition_completed)

func _create_vehicles() -> void:
	# Create first vehicle
	vehicle1 = EnhancedVehicle.new()
	vehicle1.name = "Vehicle1"
	vehicle1.position = Vector2(300, 0)
	vehicle1.modulate = Color.CYAN
	add_child(vehicle1)
	vehicles.append(vehicle1)
	
	# Create second vehicle
	vehicle2 = EnhancedVehicle.new()
	vehicle2.name = "Vehicle2"
	vehicle2.position = Vector2(-300, 0)
	vehicle2.modulate = Color.ORANGE
	add_child(vehicle2)
	vehicles.append(vehicle2)

func _create_ui() -> void:
	# Create info panel
	var info_panel := PanelContainer.new()
	info_panel.anchor_left = 0.0
	info_panel.anchor_top = 0.0
	info_panel.position = Vector2(10, 10)
	ui_container.add_child(info_panel)
	
	var info_vbox := VBoxContainer.new()
	info_panel.add_child(info_vbox)
	
	# Title
	var title := Label.new()
	title.text = "Camera System Demo"
	title.add_theme_font_size_override("font_size", 24)
	info_vbox.add_child(title)
	
	info_vbox.add_child(HSeparator.new())
	
	# Camera info
	mode_label = Label.new()
	mode_label.text = "Mode: FOLLOW"
	info_vbox.add_child(mode_label)
	
	target_label = Label.new()
	target_label.text = "Target: Vehicle1"
	info_vbox.add_child(target_label)
	
	zoom_label = Label.new()
	zoom_label.text = "Zoom: 100%"
	info_vbox.add_child(zoom_label)
	
	speed_label = Label.new()
	speed_label.text = "Speed: 0"
	info_vbox.add_child(speed_label)
	
	shake_intensity_label = Label.new()
	shake_intensity_label.text = "Shake: 0%"
	info_vbox.add_child(shake_intensity_label)
	
	# Create controls panel
	var controls_panel := PanelContainer.new()
	controls_panel.anchor_left = 1.0
	controls_panel.anchor_top = 0.0
	controls_panel.position = Vector2(-250, 10)
	ui_container.add_child(controls_panel)
	
	var controls_vbox := VBoxContainer.new()
	controls_panel.add_child(controls_vbox)
	
	# Controls title
	var controls_title := Label.new()
	controls_title.text = "Controls"
	controls_title.add_theme_font_size_override("font_size", 20)
	controls_vbox.add_child(controls_title)
	
	controls_vbox.add_child(HSeparator.new())
	
	# Movement controls
	var movement_label := Label.new()
	movement_label.text = "Movement:"
	movement_label.add_theme_font_size_override("font_size", 16)
	controls_vbox.add_child(movement_label)
	
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "W/S - Accelerate/Brake"
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "A/D - Steer"
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "SPACE - Handbrake"
	
	controls_vbox.add_child(HSeparator.new())
	
	# Camera controls
	var camera_label := Label.new()
	camera_label.text = "Camera:"
	camera_label.add_theme_font_size_override("font_size", 16)
	controls_vbox.add_child(camera_label)
	
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "V - Switch vehicle"
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "O - Overview mode"
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "F - Follow mode"
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "R - Reset position"
	
	controls_vbox.add_child(HSeparator.new())
	
	# Shake controls
	var shake_label := Label.new()
	shake_label.text = "Screen Shake:"
	shake_label.add_theme_font_size_override("font_size", 16)
	controls_vbox.add_child(shake_label)
	
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "1 - Small impact"
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "2 - Rumble"
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "3 - Explosion"
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "4 - Directional shake"
	
	controls_vbox.add_child(HSeparator.new())
	
	controls_vbox.add_child(Label.new())
	controls_vbox.get_child(-1).text = "ESC - Quit"
	
	# Create camera settings panel
	var settings_panel := PanelContainer.new()
	settings_panel.anchor_left = 0.0
	settings_panel.anchor_top = 1.0
	settings_panel.position = Vector2(10, -200)
	ui_container.add_child(settings_panel)
	
	var settings_vbox := VBoxContainer.new()
	settings_panel.add_child(settings_vbox)
	
	var settings_title := Label.new()
	settings_title.text = "Camera Settings"
	settings_title.add_theme_font_size_override("font_size", 18)
	settings_vbox.add_child(settings_title)
	
	settings_vbox.add_child(HSeparator.new())
	
	# Follow smoothing slider
	_create_slider(settings_vbox, "Follow Smoothing", camera.follow_smoothing, 0.01, 0.5,
		func(value): camera.follow_smoothing = value)
	
	# Look ahead factor slider
	_create_slider(settings_vbox, "Look Ahead", camera.look_ahead_factor, 0.0, 1.0,
		func(value): camera.look_ahead_factor = value)
	
	# Zoom smoothing slider
	_create_slider(settings_vbox, "Zoom Smoothing", camera.zoom_smoothing, 0.01, 0.5,
		func(value): camera.zoom_smoothing = value)
	
	# Speed zoom factor slider
	_create_slider(settings_vbox, "Speed Zoom Factor", camera.speed_zoom_factor, 0.0, 0.01,
		func(value): camera.speed_zoom_factor = value)

func _create_slider(parent: Control, label_text: String, initial_value: float, 
		min_value: float, max_value: float, callback: Callable) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	
	var label := Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.value = initial_value
	slider.step = 0.01
	slider.custom_minimum_size.x = 150
	slider.value_changed.connect(callback)
	hbox.add_child(slider)
	
	var value_label := Label.new()
	value_label.text = "%.2f" % initial_value
	value_label.custom_minimum_size.x = 40
	hbox.add_child(value_label)
	
	slider.value_changed.connect(func(value): value_label.text = "%.2f" % value)

func _process(_delta: float) -> void:
	# Update UI labels
	zoom_label.text = "Zoom: %d%%" % int(camera.get_zoom_percentage() * 100)
	
	# Update speed for current vehicle
	var current_vehicle := vehicles[current_vehicle_index]
	if current_vehicle:
		var velocity := current_vehicle.get_velocity()
		speed_label.text = "Speed: %d" % int(velocity.length())
	
	# Update shake intensity
	shake_intensity_label.text = "Shake: %d%%" % int(screen_shake.get_shake_intensity() * 100)

func _unhandled_input(event: InputEvent) -> void:
	# Handle all key inputs to avoid UI conflicts
	if event is InputEventKey and event.pressed:
		match event.keycode:
			# Camera controls
			KEY_V:  # V key to switch vehicles
				_switch_vehicle()
			KEY_O:  # O key for overview mode
				camera.set_overview_mode()
			KEY_F:  # F key for follow mode
				camera.set_follow_mode(vehicles[current_vehicle_index])
			KEY_R:  # R key to reset positions
				_reset_vehicle_position()
			# Shake effects
			KEY_1:  # Small impact shake
				screen_shake.shake_impact(0.5)
			KEY_2:  # Continuous rumble
				screen_shake.shake_rumble(0.3, 1.0)
			KEY_3:  # Explosion shake
				screen_shake.shake_explosion(0.8)
			KEY_4:  # Directional shake
				var direction = vehicles[current_vehicle_index].get_velocity().normalized()
				screen_shake.shake_directional(0.6, 0.5, -direction)
			# Quit
			KEY_ESCAPE:
				get_tree().quit()

func _switch_vehicle() -> void:
	current_vehicle_index = (current_vehicle_index + 1) % vehicles.size()
	camera.follow_target = vehicles[current_vehicle_index]

func _reset_vehicle_position() -> void:
	var positions := [Vector2(300, 0), Vector2(-300, 0)]
	for i in range(vehicles.size()):
		vehicles[i].position = positions[i]
		vehicles[i].linear_velocity = Vector2.ZERO
		vehicles[i].angular_velocity = 0.0
		vehicles[i].rotation = 0.0

func _on_camera_mode_changed(mode: int) -> void:
	match mode:
		0: # FOLLOW
			mode_label.text = "Mode: FOLLOW"
		1: # OVERVIEW
			mode_label.text = "Mode: OVERVIEW"
		2: # TRANSITION
			mode_label.text = "Mode: TRANSITION"

func _on_target_changed(new_target: Node2D) -> void:
	if new_target:
		target_label.text = "Target: " + new_target.name
	else:
		target_label.text = "Target: None"

func _on_transition_started() -> void:
	print("Camera transition started")

func _on_transition_completed() -> void:
	print("Camera transition completed")