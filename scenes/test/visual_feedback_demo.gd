extends Node2D

# Visual Feedback Demo Scene
# Demonstrates all visual feedback components in action

const RhythmFeedbackManager = preload("res://scripts/components/visual/rhythm_feedback_manager.gd")
const PerfectHitIndicator = preload("res://scripts/components/visual/perfect_hit_indicator.gd")
const MissIndicator = preload("res://scripts/components/visual/miss_indicator.gd")
const BeatIndicator = preload("res://scripts/components/visual/beat_indicator.gd")
const BeatVisualizationPanel = preload("res://scripts/components/visual/beat_visualization_panel.gd")
const LaneVisualFeedback = preload("res://scripts/components/visual/lane_visual_feedback.gd")
const RhythmVehicleWithLanes = preload("res://scripts/components/vehicle/rhythm_vehicle_with_lanes.gd")
const TrackSystem = preload("res://scripts/components/track/track_system.gd")
const LaneDetectionSystem = preload("res://scripts/components/track/lane_detection_system.gd")

# Components
var rhythm_feedback_manager: RhythmFeedbackManager
var perfect_hit_indicator: PerfectHitIndicator
var miss_indicator: MissIndicator
var beat_indicator: BeatIndicator
var beat_viz_panel: BeatVisualizationPanel
var lane_visual_feedback: LaneVisualFeedback
var rhythm_vehicle: RhythmVehicleWithLanes
var track_system: TrackSystem
var lane_detection: LaneDetectionSystem
var camera: Camera2D

# UI elements
var ui_container: CanvasLayer
var info_label: RichTextLabel
var controls_label: Label
var stats_label: RichTextLabel

# State tracking
var is_playing: bool = false
var beat_input_enabled: bool = true

func _ready():
	# Setup BeatManager
	get_node("/root/BeatManager").bpm = 120
	
	# Create all components
	create_managers()
	create_track()
	create_vehicle()
	create_camera()
	create_visual_feedback()
	create_ui()
	
	# Connect everything
	connect_systems()
	
	# Position vehicle at start
	position_vehicle_at_start()
	
	# Start playing
	get_node("/root/BeatManager").start()
	is_playing = true

func create_managers():
	# Create rhythm feedback manager
	rhythm_feedback_manager = RhythmFeedbackManager.new()
	rhythm_feedback_manager.add_to_group("rhythm_feedback")
	add_child(rhythm_feedback_manager)

func create_track():
	# Create track system with lanes
	track_system = TrackSystem.new()
	add_child(track_system)
	
	# Create lane detection
	lane_detection = LaneDetectionSystem.new()
	lane_detection.track_geometry = track_system.track_geometry
	add_child(lane_detection)

func create_vehicle():
	# Create rhythm vehicle with lane detection
	rhythm_vehicle = RhythmVehicleWithLanes.new()
	rhythm_vehicle.lane_detection_system = lane_detection
	add_child(rhythm_vehicle)
	
	# Connect vehicle signals
	rhythm_vehicle.speed_changed.connect(_on_vehicle_speed_changed)
	rhythm_vehicle.entered_lane.connect(_on_vehicle_entered_lane)
	rhythm_vehicle.lane_centered.connect(_on_vehicle_lane_centered)

func create_camera():
	# Create camera that follows vehicle
	camera = Camera2D.new()
	camera.make_current()
	camera.zoom = Vector2(0.5, 0.5)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.add_to_group("main_camera")
	rhythm_vehicle.add_child(camera)

func create_visual_feedback():
	# Create perfect hit indicator
	perfect_hit_indicator = PerfectHitIndicator.new()
	add_child(perfect_hit_indicator)
	
	# Create miss indicator
	miss_indicator = MissIndicator.new()
	add_child(miss_indicator)
	
	# Create enhanced beat indicator
	beat_indicator = BeatIndicator.new()
	beat_indicator.enable_streak_effects = true
	beat_indicator.position = Vector2(100, 100)
	add_child(beat_indicator)
	
	# Create lane visual feedback
	lane_visual_feedback = LaneVisualFeedback.new()
	lane_visual_feedback.lane_detection_system = lane_detection
	lane_visual_feedback.vehicle = rhythm_vehicle
	lane_visual_feedback.show_debug_overlay = false
	add_child(lane_visual_feedback)

func create_ui():
	# Create UI layer
	ui_container = CanvasLayer.new()
	add_child(ui_container)
	
	# Main container
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	ui_container.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Visual Feedback Demo"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	# Info label
	info_label = RichTextLabel.new()
	info_label.bbcode_enabled = true
	info_label.custom_minimum_size = Vector2(350, 150)
	info_label.add_theme_font_size_override("normal_font_size", 16)
	vbox.add_child(info_label)
	
	# Stats label
	stats_label = RichTextLabel.new()
	stats_label.bbcode_enabled = true
	stats_label.custom_minimum_size = Vector2(350, 100)
	stats_label.add_theme_font_size_override("normal_font_size", 16)
	vbox.add_child(stats_label)
	
	# Controls
	controls_label = Label.new()
	controls_label.text = "\n[b]Controls:[/b]\nArrows: Drive\nSpace: Hit on beat (for perfect/miss)\nD: Toggle debug overlay\nR: Reset position\nESC: Exit"
	controls_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(controls_label)
	
	# Beat visualization panel
	beat_viz_panel = BeatVisualizationPanel.new()
	beat_viz_panel.position = Vector2(get_viewport().size.x - 420, 20)
	ui_container.add_child(beat_viz_panel)
	
	update_info_display()
	update_stats_display()

func connect_systems():
	# Connect rhythm feedback to visual indicators
	rhythm_feedback_manager.perfect_hit_detected.connect(_on_perfect_hit)
	rhythm_feedback_manager.miss_detected.connect(_on_miss)
	rhythm_feedback_manager.combo_updated.connect(_on_combo_update)
	rhythm_feedback_manager.streak_broken.connect(_on_streak_broken)

func position_vehicle_at_start():
	# Position vehicle at start line
	var start_pos = track_system.start_finish_line.global_position
	var middle_lane_offset = track_system.track_geometry.get_lane_center_position(1, 0.0)
	rhythm_vehicle.reset_position(start_pos + middle_lane_offset, 0.0)

func _process(_delta: float):
	update_info_display()
	
	# Handle debug toggle
	if Input.is_action_just_pressed("ui_accept"):  # D key
		lane_visual_feedback.show_debug_overlay = not lane_visual_feedback.show_debug_overlay
	
	# Handle reset
	if Input.is_key_pressed(KEY_R):
		position_vehicle_at_start()
		rhythm_feedback_manager.reset_stats()
	
	# Handle exit
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _input(event: InputEvent):
	# Handle beat input for testing perfect/miss
	if event.is_action_pressed("ui_select") and beat_input_enabled:  # Space bar
		var quality = rhythm_feedback_manager.register_player_input(rhythm_vehicle.current_lane)
		
		# Show visual feedback based on quality
		match quality:
			RhythmFeedbackManager.HitQuality.PERFECT:
				_on_perfect_hit(0.0, rhythm_vehicle.current_lane)
			RhythmFeedbackManager.HitQuality.GOOD:
				_on_perfect_hit(0.1, rhythm_vehicle.current_lane)  # Use good color
			RhythmFeedbackManager.HitQuality.MISS:
				_on_miss(0.3, rhythm_vehicle.current_lane)

func update_info_display():
	var lane_info = rhythm_vehicle.get_lane_position()
	var speed_pct = int(rhythm_vehicle.get_speed_percentage() * 100)
	
	info_label.text = "[b]Vehicle Status:[/b]\n"
	info_label.text += "Current Lane: %d\n" % lane_info.current_lane
	info_label.text += "Offset from Center: %.1f\n" % lane_info.offset_from_center
	info_label.text += "Is Centered: %s\n" % str(lane_info.is_centered)
	info_label.text += "Speed: %d%%\n" % speed_pct
	info_label.text += "Combo: %d\n" % rhythm_feedback_manager.get_current_combo()
	info_label.text += "Multiplier: %.1fx" % rhythm_feedback_manager.get_multiplier()

func update_stats_display():
	var stats = rhythm_feedback_manager.get_performance_stats()
	var accuracy_pct = int(stats.accuracy * 100)
	
	stats_label.text = "[b]Performance:[/b]\n"
	stats_label.text += "Accuracy: %d%%\n" % accuracy_pct
	stats_label.text += "Perfect: %d/%d\n" % [stats.perfect_beats, stats.total_beats]
	stats_label.text += "Best Combo: %d\n" % stats.best_combo
	stats_label.text += "Perfect Streak: %d" % stats.perfect_streak

func _on_perfect_hit(accuracy: float, lane: int):
	perfect_hit_indicator.trigger_perfect_hit(RhythmFeedbackManager.HitQuality.PERFECT, rhythm_vehicle.global_position)
	beat_indicator.trigger_perfect_pulse()
	update_stats_display()

func _on_miss(accuracy: float, lane: int):
	miss_indicator.trigger_miss(rhythm_vehicle.global_position)
	update_stats_display()

func _on_combo_update(combo: int):
	update_info_display()
	update_stats_display()

func _on_streak_broken():
	miss_indicator.flash_border()
	update_stats_display()

func _on_vehicle_speed_changed(speed: float):
	# Could add speed-based visual effects
	pass

func _on_vehicle_entered_lane(lane: int):
	# Could add lane change effects
	pass

func _on_vehicle_lane_centered(lane: int):
	# Could add centering bonus effects
	pass