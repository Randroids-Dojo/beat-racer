# Track demonstration scene
extends Node2D

var TrackGeometry = preload("res://scripts/components/track/track_geometry.gd")

var track: Node2D
var camera: Camera2D

func _ready() -> void:
	print("Track demo starting...")
	
	# Create track geometry
	track = TrackGeometry.new()
	track.name = "TrackGeometry"
	add_child(track)
	
	# Create camera
	camera = Camera2D.new()
	camera.zoom = Vector2(0.3, 0.3)
	add_child(camera)
	
	# Create UI
	var ui = CanvasLayer.new()
	add_child(ui)
	
	var info = Label.new()
	info.text = "Track Demo - Use arrow keys to move camera, ESC to exit"
	info.position = Vector2(10, 10)
	ui.add_child(info)
	
	print("Track demo initialized")

func _process(delta: float) -> void:
	var move = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		move.x -= 1
	if Input.is_action_pressed("ui_right"):
		move.x += 1
	if Input.is_action_pressed("ui_up"):
		move.y -= 1
	if Input.is_action_pressed("ui_down"):
		move.y += 1
	
	camera.position += move * 500 * delta
	
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()