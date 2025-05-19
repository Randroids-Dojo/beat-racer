# Test scene for demonstrating track functionality
extends Node2D

@export var camera_zoom := 0.5
@export var camera_speed := 500.0

var track_system: TrackSystem
var camera: Camera2D
var info_label: Label

# Test vehicle simulation
var test_position := Vector2.ZERO
var test_lane := 1
var test_progress := 0.0
var test_speed := 0.1  # Progress per second


func _ready() -> void:
	_setup_scene()
	_create_ui()
	_start_test()


func _setup_scene() -> void:
	# Create track system
	track_system = TrackSystem.new()
	track_system.name = "TrackSystem"
	add_child(track_system)
	
	# Create camera
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	camera.enabled = true
	add_child(camera)
	camera.make_current()
	
	# Create background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.05)
	bg.z_index = -10
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)


func _create_ui() -> void:
	var ui_layer := CanvasLayer.new()
	ui_layer.name = "UI"
	add_child(ui_layer)
	
	# Instructions panel
	var panel := Panel.new()
	panel.set_anchor_and_offset(SIDE_LEFT, 0, 10)
	panel.set_anchor_and_offset(SIDE_TOP, 0, 10)
	panel.set_anchor_and_offset(SIDE_RIGHT, 0, 300)
	panel.set_anchor_and_offset(SIDE_BOTTOM, 0, 200)
	ui_layer.add_child(panel)
	
	# Info label
	info_label = Label.new()
	info_label.set_anchor_and_offset(SIDE_LEFT, 0, 10)
	info_label.set_anchor_and_offset(SIDE_TOP, 0, 10)
	info_label.set_anchor_and_offset(SIDE_RIGHT, 1, -10)
	info_label.set_anchor_and_offset(SIDE_BOTTOM, 1, -10)
	info_label.text = "Track Test Scene
	
Controls:
- Arrow Keys: Move camera
- Mouse Wheel: Zoom in/out
- 1,2,3: Switch test lanes
- Space: Start/stop movement
- R: Reset position"
	panel.add_child(info_label)
	
	# BPM control
	if BeatManager:
		var bpm_label := Label.new()
		bpm_label.text = "BPM:"
		bpm_label.position = Vector2(10, 220)
		ui_layer.add_child(bpm_label)
		
		var bpm_slider := HSlider.new()
		bpm_slider.min_value = 60
		bpm_slider.max_value = 240
		bpm_slider.value = BeatManager.bpm
		bpm_slider.position = Vector2(50, 220)
		bpm_slider.size.x = 200
		bpm_slider.value_changed.connect(_on_bpm_changed)
		ui_layer.add_child(bpm_slider)
		
		var bpm_value := Label.new()
		bpm_value.text = str(int(BeatManager.bpm))
		bpm_value.position = Vector2(260, 220)
		ui_layer.add_child(bpm_value)
		
		bpm_slider.value_changed.connect(func(value): bpm_value.text = str(int(value)))


func _start_test() -> void:
	# Start at the beginning of the middle lane
	test_lane = 1
	test_progress = 0.0
	test_position = track_system.track_geometry.get_lane_center_position(test_lane, test_progress)
	
	# Start the beat manager
	if BeatManager:
		BeatManager.start()


func _process(delta: float) -> void:
	_handle_camera_movement(delta)
	_update_test_vehicle(delta)
	_update_info_display()


func _handle_camera_movement(delta: float) -> void:
	var input_vector := Vector2.ZERO
	
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	
	camera.position += input_vector * camera_speed * delta


func _update_test_vehicle(delta: float) -> void:
	if Input.is_action_just_pressed("ui_select"):
		test_speed = 0.0 if test_speed > 0 else 0.1
	
	if Input.is_action_just_pressed("ui_text_submit"):
		test_progress = 0.0
		test_position = track_system.track_geometry.get_lane_center_position(test_lane, test_progress)
	
	# Lane switching
	if Input.is_key_pressed(KEY_1):
		test_lane = 0
	elif Input.is_key_pressed(KEY_2):
		test_lane = 1
	elif Input.is_key_pressed(KEY_3):
		test_lane = 2
	
	# Update position
	test_progress += test_speed * delta
	if test_progress >= 1.0:
		test_progress -= 1.0
	
	test_position = track_system.track_geometry.get_lane_center_position(test_lane, test_progress)
	queue_redraw()


func _update_info_display() -> void:
	var current_beat := 0
	if BeatManager:
		current_beat = BeatManager.get_current_beat()
	
	var info_text := "Track Test Scene

Controls:
- Arrow Keys: Move camera
- Mouse Wheel: Zoom in/out
- 1,2,3: Switch test lanes
- Space: Start/stop movement
- R: Reset position

Status:
- Current Lane: %d
- Track Progress: %.2f%%
- Current Beat: %d
- Speed: %s" % [
		test_lane,
		test_progress * 100,
		current_beat,
		"Moving" if test_speed > 0 else "Stopped"
	]
	
	info_label.text = info_text


func _draw() -> void:
	# Draw test vehicle
	draw_circle(test_position, 20.0, Color.CYAN)
	
	# Draw direction indicator
	var next_progress := test_progress + 0.01
	if next_progress >= 1.0:
		next_progress -= 1.0
	var next_pos := track_system.track_geometry.get_lane_center_position(test_lane, next_progress)
	var direction := (next_pos - test_position).normalized()
	draw_line(test_position, test_position + direction * 30, Color.YELLOW, 3.0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 1.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom *= 0.9
			camera.zoom = camera.zoom.clamp(Vector2(0.1, 0.1), Vector2(2.0, 2.0))


func _on_bpm_changed(value: float) -> void:
	if BeatManager:
		BeatManager.set_bpm(value)