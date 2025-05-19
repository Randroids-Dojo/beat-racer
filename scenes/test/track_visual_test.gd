# Basic visual test for track system
extends Node2D

func _ready() -> void:
	# Create the track
	var TrackGeo = preload("res://scripts/components/track/track_geometry.gd")
	var track = TrackGeo.new()
	add_child(track)
	
	# Create camera
	var cam = Camera2D.new()
	cam.zoom = Vector2(0.3, 0.3)
	add_child(cam)
	
	# Add instructions
	var ui = CanvasLayer.new()
	add_child(ui)
	
	var label = Label.new()
	label.text = "Track Visual Test - Press ESC to exit"
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 20)
	ui.add_child(label)
	
	print("Track visual test ready")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()