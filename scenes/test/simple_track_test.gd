# Simple track test to verify geometry rendering
extends Node2D

const TrackGeometry = preload("res://scripts/components/track/track_geometry.gd")
const TrackBoundaries = preload("res://scripts/components/track/track_boundaries.gd")
const StartFinishLine = preload("res://scripts/components/track/start_finish_line.gd")
const BeatMarker = preload("res://scripts/components/track/beat_marker.gd")
const TrackSystem = preload("res://scripts/components/track/track_system.gd")

var track_system: Node2D
var camera: Camera2D
var info_label: Label

func _ready() -> void:
	_setup_scene()
	_create_ui()
	print("Simple Track Test initialized")

func _setup_scene() -> void:
	# Create track system
	track_system = TrackSystem.new()
	track_system.name = "TrackSystem"
	add_child(track_system)
	
	# Create camera
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(0.3, 0.3)
	camera.enabled = true
	add_child(camera)
	camera.make_current()
	
	# Create background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.05)
	bg.position = Vector2(-2000, -2000)
	bg.size = Vector2(4000, 4000)
	bg.z_index = -10
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
	panel.set_anchor_and_offset(SIDE_BOTTOM, 0, 150)
	ui_layer.add_child(panel)
	
	# Info label
	info_label = Label.new()
	info_label.set_anchor_and_offset(SIDE_LEFT, 0, 10)
	info_label.set_anchor_and_offset(SIDE_TOP, 0, 10)
	info_label.set_anchor_and_offset(SIDE_RIGHT, 1, -10)
	info_label.set_anchor_and_offset(SIDE_BOTTOM, 1, -10)
	info_label.text = "Simple Track Test
	
Controls:
- Arrow Keys: Move camera
- Mouse Wheel: Zoom in/out
- ESC: Exit

Track system created successfully!"
	panel.add_child(info_label)

func _process(delta: float) -> void:
	_handle_camera_movement(delta)

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
	
	camera.position += input_vector * 500.0 * delta

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 1.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom *= 0.9
			camera.zoom = camera.zoom.clamp(Vector2(0.1, 0.1), Vector2(2.0, 2.0))
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()