# Vehicle and track integration test scene
extends Node2D

const TrackSystem = preload("res://scripts/components/track/track_system.gd")
const Vehicle = preload("res://scripts/components/vehicle/vehicle.gd")

var track_system: TrackSystem
var vehicle: Vehicle
var camera: Camera2D
var ui_container: CanvasLayer
var speed_label: Label
var lane_label: Label


func _ready() -> void:
	create_track()
	create_vehicle()
	create_camera()
	create_ui()
	position_vehicle_at_start()


func create_track() -> void:
	track_system = TrackSystem.new()
	add_child(track_system)


func create_vehicle() -> void:
	vehicle = Vehicle.new()
	add_child(vehicle)
	
	# Connect signals
	vehicle.speed_changed.connect(_on_vehicle_speed_changed)
	vehicle.direction_changed.connect(_on_vehicle_direction_changed)


func create_camera() -> void:
	camera = Camera2D.new()
	camera.make_current()
	camera.zoom = Vector2(0.5, 0.5)
	vehicle.add_child(camera)


func create_ui() -> void:
	ui_container = CanvasLayer.new()
	add_child(ui_container)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	ui_container.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Vehicle & Track Test"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	# Speed display
	speed_label = Label.new()
	speed_label.text = "Speed: 0 km/h"
	speed_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(speed_label)
	
	# Lane display
	lane_label = Label.new()
	lane_label.text = "Lane: -"
	lane_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(lane_label)
	
	# Controls
	var controls = Label.new()
	controls.text = "Controls:\nArrow Keys - Drive\nR - Reset position\nESC - Exit"
	controls.add_theme_font_size_override("font_size", 14)
	vbox.add_child(controls)


func position_vehicle_at_start() -> void:
	# Position vehicle at start/finish line in middle lane
	var start_pos = track_system.start_finish_line.global_position
	var middle_lane_offset = track_system.track_geometry.get_lane_center_position(1, 0.0)
	vehicle.reset_position(start_pos + middle_lane_offset, 0.0)


func _process(_delta: float) -> void:
	update_lane_display()
	
	# Handle reset input
	if Input.is_action_just_pressed("ui_select"):
		position_vehicle_at_start()
	
	# Handle exit
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()


func update_lane_display() -> void:
	var current_lane = track_system.get_current_lane(vehicle.global_position)
	lane_label.text = "Lane: %d" % (current_lane + 1)  # Display as 1-3 instead of 0-2


func _on_vehicle_speed_changed(speed: float) -> void:
	# Convert to km/h for display
	var kmh = speed * 0.36  # Rough conversion from pixels/s to km/h
	speed_label.text = "Speed: %d km/h" % int(kmh)


func _on_vehicle_direction_changed(_direction: float) -> void:
	# Could display direction if needed
	pass