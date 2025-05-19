# Rhythm Vehicle Demo Scene
extends Node2D

const TrackSystem = preload("res://scripts/components/track/track_system.gd")
const RhythmVehicle = preload("res://scripts/components/vehicle/rhythm_vehicle.gd")
const BeatVisualizationPanel = preload("res://scripts/components/visual/beat_visualization_panel.gd")

var track_system: TrackSystem
var rhythm_vehicle: RhythmVehicle
var camera: Camera2D
var ui_container: CanvasLayer
var speed_label: Label
var lane_label: Label
var rhythm_stats_label: RichTextLabel
var beat_viz_panel: BeatVisualizationPanel
var boost_bar: ProgressBar


func _ready() -> void:
	get_node("/root/BeatManager").bpm = 120
	
	create_track()
	create_rhythm_vehicle()
	create_camera()
	create_ui()
	create_beat_visualization()
	position_vehicle_at_start()
	
	# Start beat playback
	get_node("/root/BeatManager").start()


func create_track() -> void:
	track_system = TrackSystem.new()
	add_child(track_system)


func create_rhythm_vehicle() -> void:
	rhythm_vehicle = RhythmVehicle.new()
	add_child(rhythm_vehicle)
	
	# Connect signals
	rhythm_vehicle.speed_changed.connect(_on_vehicle_speed_changed)
	rhythm_vehicle.direction_changed.connect(_on_vehicle_direction_changed)
	rhythm_vehicle.beat_hit.connect(_on_beat_hit)
	rhythm_vehicle.beat_missed.connect(_on_beat_missed)
	rhythm_vehicle.boost_applied.connect(_on_boost_applied)


func create_camera() -> void:
	camera = Camera2D.new()
	camera.make_current()
	camera.zoom = Vector2(0.5, 0.5)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	rhythm_vehicle.add_child(camera)


func create_ui() -> void:
	ui_container = CanvasLayer.new()
	add_child(ui_container)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	ui_container.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Rhythm Vehicle Demo"
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
	
	# Boost bar
	var boost_container = HBoxContainer.new()
	vbox.add_child(boost_container)
	
	var boost_label = Label.new()
	boost_label.text = "Boost: "
	boost_label.add_theme_font_size_override("font_size", 16)
	boost_container.add_child(boost_label)
	
	boost_bar = ProgressBar.new()
	boost_bar.custom_minimum_size = Vector2(100, 20)
	boost_bar.max_value = 1.0
	boost_bar.value = 0.0
	boost_bar.show_percentage = false
	boost_container.add_child(boost_bar)
	
	# Rhythm stats
	rhythm_stats_label = RichTextLabel.new()
	rhythm_stats_label.bbcode_enabled = true
	rhythm_stats_label.custom_minimum_size = Vector2(300, 100)
	rhythm_stats_label.add_theme_font_size_override("normal_font_size", 16)
	vbox.add_child(rhythm_stats_label)
	
	# Controls
	var controls = Label.new()
	controls.text = "\nControls:\nArrow Keys - Drive (accelerate on beat!)\nSpace - Toggle metronome\nR - Reset position\nESC - Exit"
	controls.add_theme_font_size_override("font_size", 14)
	vbox.add_child(controls)
	
	update_rhythm_stats()


func create_beat_visualization() -> void:
	beat_viz_panel = BeatVisualizationPanel.new()
	beat_viz_panel.position = Vector2(get_viewport().size.x - 420, 20)
	ui_container.add_child(beat_viz_panel)


func position_vehicle_at_start() -> void:
	# Position vehicle at start/finish line in middle lane
	var start_pos = track_system.start_finish_line.global_position
	var middle_lane_offset = track_system.track_geometry.get_lane_center_position(1, 0.0)
	rhythm_vehicle.reset_position(start_pos + middle_lane_offset, 0.0)
	rhythm_vehicle.reset_rhythm_stats()


func _process(_delta: float) -> void:
	update_lane_display()
	update_boost_display()
	
	# Handle reset input
	if Input.is_action_just_pressed("ui_select"):
		position_vehicle_at_start()
		rhythm_vehicle.reset_rhythm_stats()
	
	# Toggle metronome
	if Input.is_key_pressed(KEY_SPACE):
		var playback_sync = beat_viz_panel.playback_sync
		if playback_sync:
			playback_sync.toggle_metronome()
	
	# Handle exit
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()


func update_lane_display() -> void:
	if not rhythm_vehicle or not track_system:
		return
	var current_lane = track_system.get_current_lane(rhythm_vehicle.global_position)
	lane_label.text = "Lane: %d" % (current_lane + 1)  # Display as 1-3 instead of 0-2


func update_boost_display() -> void:
	if not rhythm_vehicle:
		return
	var stats = rhythm_vehicle.get_rhythm_stats()
	boost_bar.value = float(stats.current_boost) / rhythm_vehicle.boost_power


func update_rhythm_stats() -> void:
	var stats = rhythm_vehicle.get_rhythm_stats()
	var accuracy_percent = stats.accuracy * 100.0
	var streak = 0  # Could track consecutive perfect beats
	
	var stats_text = "[b]Rhythm Stats:[/b]\n"
	stats_text += "Perfect Beats: %d/%d\n" % [stats.perfect_beats, stats.total_beats]
	stats_text += "Accuracy: %.1f%%\n" % accuracy_percent
	
	# Color code accuracy
	var accuracy_color = "green" if accuracy_percent > 80 else "yellow" if accuracy_percent > 60 else "red"
	stats_text += "[color=%s]Rating: %s[/color]" % [accuracy_color, get_accuracy_rating(accuracy_percent)]
	
	rhythm_stats_label.text = stats_text


func get_accuracy_rating(accuracy: float) -> String:
	if accuracy >= 95:
		return "Perfect!"
	elif accuracy >= 85:
		return "Excellent!"
	elif accuracy >= 75:
		return "Great!"
	elif accuracy >= 65:
		return "Good"
	elif accuracy >= 50:
		return "OK"
	else:
		return "Keep Practicing"


func _on_vehicle_speed_changed(speed: float) -> void:
	# Convert to km/h for display
	var kmh = speed * 0.36  # Rough conversion from pixels/s to km/h
	speed_label.text = "Speed: %d km/h" % int(kmh)


func _on_vehicle_direction_changed(_direction: float) -> void:
	# Could display direction if needed
	pass


func _on_beat_hit(beat_number: int, perfect: bool) -> void:
	update_rhythm_stats()
	
	# Visual feedback for beat hit
	var color = Color.GREEN if perfect else Color.YELLOW
	flash_border(color)


func _on_beat_missed(beat_number: int) -> void:
	update_rhythm_stats()
	flash_border(Color.RED)


func _on_boost_applied(power: float) -> void:
	# Could add particle effects or other visual feedback
	pass


func flash_border(color: Color) -> void:
	# Create a border flash effect
	var border = ColorRect.new()
	border.color = color
	border.color.a = 0.3
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_container.add_child(border)
	
	var tween = create_tween()
	tween.tween_property(border, "color:a", 0.0, 0.3)
	tween.tween_callback(border.queue_free)