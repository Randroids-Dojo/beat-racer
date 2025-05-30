# Vehicle Feel Demo
# Tests the enhanced vehicle physics and visual effects
extends Node2D

@onready var vehicle: EnhancedVehicle = $EnhancedVehicle
@onready var track_system: TrackSystem = $TrackSystem
@onready var camera: Camera2D = $Camera2D
@onready var ui_panel: Control = $CanvasLayer/UIPanel
@onready var stats_label: Label = $CanvasLayer/UIPanel/StatsLabel
@onready var controls_label: Label = $CanvasLayer/UIPanel/ControlsLabel

# UI Controls
@onready var acceleration_curve_editor: Control = $CanvasLayer/UIPanel/CurveEditors/AccelerationCurve
@onready var deceleration_curve_editor: Control = $CanvasLayer/UIPanel/CurveEditors/DecelerationCurve
@onready var turn_resistance_curve_editor: Control = $CanvasLayer/UIPanel/CurveEditors/TurnResistanceCurve
@onready var physics_sliders: Control = $CanvasLayer/UIPanel/PhysicsSliders
@onready var visual_toggles: Control = $CanvasLayer/UIPanel/VisualToggles

# Camera shake
var trauma := 0.0
var trauma_power := 2.0
var max_offset := Vector2(10, 10)
var max_rotation := 0.05
var trauma_decay := 2.0


func _ready():
	print("=== Vehicle Feel Demo Starting ===")
	
	# Setup vehicle
	setup_vehicle()
	
	# Setup UI
	setup_ui()
	
	# Setup camera
	setup_camera()
	
	# Add debug info
	controls_label.text = """Controls:
Arrow Keys / WASD - Drive
R - Reset Position
Tab - Toggle UI
1-5 - Test Different Physics Presets
Space - Handbrake (test drift)"""
	
	print("Vehicle Feel Demo ready!")


func setup_vehicle():
	"""Configure the enhanced vehicle"""
	if not vehicle:
		print("ERROR: No vehicle found!")
		return
	
	# Set initial position
	var start_pos = track_system.get_start_position() if track_system else Vector2(400, 300)
	vehicle.reset_position(start_pos, 0)
	
	# Connect signals
	vehicle.state_changed.connect(_on_vehicle_state_changed)
	vehicle.drift_started.connect(_on_drift_started)
	vehicle.drift_ended.connect(_on_drift_ended)
	vehicle.impact_occurred.connect(_on_impact_occurred)
	
	# Enable all visual features
	vehicle.enable_banking = true
	vehicle.enable_screen_shake = true
	vehicle.enable_tire_smoke = true
	vehicle.enable_speed_particles = true


func setup_camera():
	"""Configure the camera for following the vehicle"""
	if not camera:
		camera = Camera2D.new()
		add_child(camera)
	
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.make_current()
	
	# Add reference to camera in vehicle for screen shake
	vehicle.camera = camera


func setup_ui():
	"""Setup UI controls for tweaking vehicle parameters"""
	if not ui_panel:
		# Create basic UI if not in scene
		var canvas_layer = CanvasLayer.new()
		add_child(canvas_layer)
		
		ui_panel = Panel.new()
		ui_panel.position = Vector2(10, 10)
		ui_panel.size = Vector2(300, 600)
		canvas_layer.add_child(ui_panel)
		
		stats_label = Label.new()
		stats_label.position = Vector2(10, 10)
		ui_panel.add_child(stats_label)
	
	# Create physics parameter sliders
	create_physics_sliders()
	
	# Create visual toggle checkboxes
	create_visual_toggles()


func create_physics_sliders():
	"""Create sliders for adjusting physics parameters"""
	if not physics_sliders:
		physics_sliders = VBoxContainer.new()
		physics_sliders.position = Vector2(10, 200)
		ui_panel.add_child(physics_sliders)
	
	# Max Speed
	add_slider("Max Speed", 100, 1000, vehicle.max_speed, func(value): vehicle.max_speed = value)
	
	# Acceleration
	add_slider("Acceleration", 100, 2000, vehicle.acceleration, func(value): vehicle.acceleration = value)
	
	# Turn Speed
	add_slider("Turn Speed", 1.0, 5.0, vehicle.turn_speed, func(value): vehicle.turn_speed = value, 0.1)
	
	# Drift Factor
	add_slider("Drift Factor", 0.5, 1.0, vehicle.drift_factor, func(value): vehicle.drift_factor = value, 0.01)
	
	# Momentum Preservation
	add_slider("Momentum", 0.8, 0.99, vehicle.momentum_preservation, func(value): vehicle.momentum_preservation = value, 0.01)
	
	# Slip Angle Threshold
	add_slider("Slip Threshold", 5.0, 30.0, vehicle.slip_angle_threshold, func(value): vehicle.slip_angle_threshold = value)
	
	# Bank Angle
	add_slider("Bank Angle", 0.0, 20.0, vehicle.max_bank_angle, func(value): vehicle.max_bank_angle = value)


func create_visual_toggles():
	"""Create checkboxes for toggling visual effects"""
	if not visual_toggles:
		visual_toggles = VBoxContainer.new()
		visual_toggles.position = Vector2(10, 450)
		ui_panel.add_child(visual_toggles)
	
	# Banking
	add_checkbox("Enable Banking", vehicle.enable_banking, func(checked): vehicle.enable_banking = checked)
	
	# Screen Shake
	add_checkbox("Screen Shake", vehicle.enable_screen_shake, func(checked): vehicle.enable_screen_shake = checked)
	
	# Tire Smoke
	add_checkbox("Tire Smoke", vehicle.enable_tire_smoke, func(checked): vehicle.enable_tire_smoke = checked)
	
	# Speed Particles
	add_checkbox("Speed Particles", vehicle.enable_speed_particles, func(checked): vehicle.enable_speed_particles = checked)


func add_slider(label_text: String, min_val: float, max_val: float, initial: float, callback: Callable, step: float = 1.0):
	"""Helper to add a labeled slider"""
	var container = HBoxContainer.new()
	physics_sliders.add_child(container)
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 120
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = initial
	slider.step = step
	slider.custom_minimum_size.x = 150
	slider.value_changed.connect(callback)
	container.add_child(slider)
	
	var value_label = Label.new()
	value_label.text = str(initial)
	value_label.custom_minimum_size.x = 50
	container.add_child(value_label)
	
	# Update value label when slider changes
	slider.value_changed.connect(func(value): value_label.text = "%.2f" % value)


func add_checkbox(label_text: String, initial: bool, callback: Callable):
	"""Helper to add a checkbox"""
	var checkbox = CheckBox.new()
	checkbox.text = label_text
	checkbox.button_pressed = initial
	checkbox.toggled.connect(callback)
	visual_toggles.add_child(checkbox)


func _process(delta: float):
	"""Update camera and UI"""
	# Follow vehicle with camera
	if camera and vehicle:
		camera.global_position = camera.global_position.lerp(vehicle.global_position, 5.0 * delta)
		
		# Apply camera shake
		if trauma > 0:
			trauma = max(trauma - trauma_decay * delta, 0)
			apply_camera_shake()
	
	# Update stats display
	update_stats_display()
	
	# Handle input
	handle_input()


func apply_camera_shake():
	"""Apply shake to camera based on trauma"""
	var amount = pow(trauma, trauma_power)
	
	# Calculate offset
	var offset_x = max_offset.x * amount * randf_range(-1, 1)
	var offset_y = max_offset.y * amount * randf_range(-1, 1)
	camera.offset = Vector2(offset_x, offset_y)
	
	# Calculate rotation
	camera.rotation = max_rotation * amount * randf_range(-1, 1)


func add_trauma(amount: float):
	"""Add trauma for camera shake"""
	trauma = min(trauma + amount, 1.0)


func update_stats_display():
	"""Update the stats label with vehicle information"""
	if not stats_label or not vehicle:
		return
	
	var stats = vehicle.get_vehicle_stats()
	stats_label.text = """Vehicle Stats:
State: %s
Speed: %.0f / %.0f
Speed %%: %.1f%%
Slip Angle: %.1f°
Drifting: %s
Bank Angle: %.1f°
Accel Factor: %.2f""" % [
		stats.state,
		stats.speed,
		vehicle.max_speed,
		stats.speed_percentage * 100,
		stats.slip_angle,
		"Yes" if stats.is_drifting else "No",
		stats.bank_angle,
		stats.acceleration_factor
	]


func handle_input():
	"""Handle demo-specific input"""
	# Reset position
	if Input.is_action_just_pressed("ui_cancel"):  # Usually Escape
		var start_pos = track_system.get_start_position() if track_system else Vector2(400, 300)
		vehicle.reset_position(start_pos, 0)
	
	# Toggle UI
	if Input.is_action_just_pressed("ui_focus_next"):  # Usually Tab
		ui_panel.visible = !ui_panel.visible
	
	# Test physics presets
	if Input.is_key_pressed(KEY_1):
		apply_preset_arcade()
	elif Input.is_key_pressed(KEY_2):
		apply_preset_realistic()
	elif Input.is_key_pressed(KEY_3):
		apply_preset_drift()
	elif Input.is_key_pressed(KEY_4):
		apply_preset_heavy()
	elif Input.is_key_pressed(KEY_5):
		apply_preset_responsive()
	
	# Handbrake for testing drift
	if Input.is_action_pressed("ui_select"):  # Usually Space
		vehicle.friction = 100.0  # Low friction for sliding
		vehicle.drift_factor = 0.7  # More slide
	else:
		vehicle.friction = 600.0  # Normal friction
		vehicle.drift_factor = 0.95  # Normal drift


func apply_preset_arcade():
	"""Arcade-style physics preset"""
	vehicle.max_speed = 800.0
	vehicle.acceleration = 1200.0
	vehicle.turn_speed = 4.0
	vehicle.drift_factor = 0.98
	vehicle.momentum_preservation = 0.95
	print("Applied Arcade preset")


func apply_preset_realistic():
	"""Realistic physics preset"""
	vehicle.max_speed = 600.0
	vehicle.acceleration = 600.0
	vehicle.turn_speed = 2.5
	vehicle.drift_factor = 0.92
	vehicle.momentum_preservation = 0.88
	print("Applied Realistic preset")


func apply_preset_drift():
	"""Drift-focused preset"""
	vehicle.max_speed = 700.0
	vehicle.acceleration = 800.0
	vehicle.turn_speed = 3.5
	vehicle.drift_factor = 0.85
	vehicle.momentum_preservation = 0.82
	vehicle.slip_angle_threshold = 10.0
	print("Applied Drift preset")


func apply_preset_heavy():
	"""Heavy vehicle preset"""
	vehicle.max_speed = 500.0
	vehicle.acceleration = 400.0
	vehicle.turn_speed = 2.0
	vehicle.drift_factor = 0.88
	vehicle.momentum_preservation = 0.85
	print("Applied Heavy preset")


func apply_preset_responsive():
	"""Highly responsive preset"""
	vehicle.max_speed = 900.0
	vehicle.acceleration = 1500.0
	vehicle.turn_speed = 4.5
	vehicle.drift_factor = 0.99
	vehicle.momentum_preservation = 0.97
	print("Applied Responsive preset")


# Signal handlers
func _on_vehicle_state_changed(old_state: EnhancedVehicle.VehicleState, new_state: EnhancedVehicle.VehicleState):
	"""Handle vehicle state changes"""
	print("Vehicle state changed: %s -> %s" % [
		EnhancedVehicle.VehicleState.keys()[old_state],
		EnhancedVehicle.VehicleState.keys()[new_state]
	])


func _on_drift_started():
	"""Handle drift start"""
	print("Drift started!")
	add_trauma(0.2)


func _on_drift_ended():
	"""Handle drift end"""
	print("Drift ended!")


func _on_impact_occurred(force: float):
	"""Handle vehicle impact"""
	print("Impact! Force: %.0f" % force)
	add_trauma(clamp(force / 1000.0, 0.1, 1.0))


# Note: Camera shake is handled by the demo's add_trauma method