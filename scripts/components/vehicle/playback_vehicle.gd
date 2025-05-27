extends Node2D
class_name PlaybackVehicle

# Playback Vehicle
# A ghost vehicle that follows recorded paths
# Triggers sounds based on lane position during playback

signal lane_changed(from_lane: int, to_lane: int)
signal crossed_start_line()
signal playback_started()
signal playback_stopped()

# Visual settings
@export var ghost_alpha: float = 0.5  # Transparency for ghost vehicle
@export var trail_enabled: bool = true  # Show trail effect
@export var trail_length: int = 20  # Number of trail segments
@export var ghost_color: Color = Color(0.3, 0.8, 1.0, 0.5)  # Light blue ghost

# Audio settings
@export var trigger_sounds: bool = true  # Trigger lane sounds during playback
@export var sound_volume_modifier: float = 0.8  # Volume multiplier for ghost sounds

# Debug settings
@export var debug_logging: bool = false

# Components
var path_player: PathPlayer
var lane_sound_system: LaneSoundSystem
var visual_sprite: Sprite2D
var trail_nodes: Array[Sprite2D] = []

# State tracking
var current_lane: int = -1
var last_position: Vector2
var is_active: bool = false


func _ready():
	_log("=== PlaybackVehicle Initialization ===")
	
	# Create path player component
	path_player = PathPlayer.new()
	path_player.debug_logging = debug_logging
	add_child(path_player)
	
	# Connect path player signals
	path_player.position_updated.connect(_on_position_updated)
	path_player.playback_started.connect(_on_playback_started)
	path_player.playback_stopped.connect(_on_playback_stopped)
	path_player.loop_completed.connect(_on_loop_completed)
	
	# Create visual representation
	_create_visual()
	
	# Create trail if enabled
	if trail_enabled:
		_create_trail()
	
	_log("PlaybackVehicle ready")
	_log("===================================")


func _log(message: String) -> void:
	if debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] PlaybackVehicle: %s" % [timestamp, message])


func setup(lane_sound_sys: LaneSoundSystem):
	"""Setup with required references"""
	lane_sound_system = lane_sound_sys
	
	if not lane_sound_system and trigger_sounds:
		push_warning("No LaneSoundSystem provided - sound triggering disabled")
		trigger_sounds = false


func load_recording(recording: LapRecorder.LapRecording) -> bool:
	"""Load a lap recording for playback"""
	return path_player.load_recording(recording)


func start_playback():
	"""Start playing the loaded recording"""
	path_player.start_playback()


func stop_playback():
	"""Stop playback"""
	path_player.stop_playback()


func pause_playback():
	"""Pause playback"""
	path_player.pause_playback()


func _create_visual():
	"""Create the ghost vehicle visual"""
	visual_sprite = Sprite2D.new()
	visual_sprite.modulate = ghost_color
	add_child(visual_sprite)
	
	# Create simple vehicle shape with CanvasItem draw
	visual_sprite.set_script(preload("res://scripts/components/vehicle/ghost_vehicle_visual.gd") if ResourceLoader.exists("res://scripts/components/vehicle/ghost_vehicle_visual.gd") else null)
	
	# If script doesn't exist, use a colored rectangle
	if not visual_sprite.has_method("_draw"):
		var texture = ImageTexture.new()
		var image = Image.create(30, 20, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		texture.set_image(image)
		visual_sprite.texture = texture
		visual_sprite.scale = Vector2(1, 1)


func _create_trail():
	"""Create trail effect nodes"""
	for i in trail_length:
		var trail_sprite = Sprite2D.new()
		trail_sprite.modulate = ghost_color
		trail_sprite.modulate.a = ghost_alpha * (1.0 - float(i) / float(trail_length))
		trail_sprite.z_index = -1 - i
		
		# Copy visual setup
		if visual_sprite.texture:
			trail_sprite.texture = visual_sprite.texture
			trail_sprite.scale = visual_sprite.scale * (1.0 - float(i) / float(trail_length) * 0.3)
		
		add_child(trail_sprite)
		trail_nodes.append(trail_sprite)
		trail_sprite.visible = false


func _on_position_updated(position: Vector2, rotation: float, lane: int):
	"""Handle position updates from path player"""
	# Update position and rotation
	global_position = position
	global_rotation = rotation
	
	# Update trail
	if trail_enabled:
		_update_trail()
	
	# Check for lane changes
	if lane != current_lane and lane >= 0:
		var old_lane = current_lane
		current_lane = lane
		
		if old_lane >= 0:
			emit_signal("lane_changed", old_lane, current_lane)
			_trigger_lane_sound(current_lane)
	
	# Check for start line crossing
	if last_position != Vector2.ZERO:
		# Simple check - could be improved with actual track geometry
		var movement = position - last_position
		if movement.length() > 100:  # Teleport detected (lap wrap)
			emit_signal("crossed_start_line")
	
	last_position = position


func _update_trail():
	"""Update trail positions"""
	if trail_nodes.is_empty():
		return
	
	# Shift trail positions
	for i in range(trail_nodes.size() - 1, 0, -1):
		var prev_node = trail_nodes[i - 1]
		var curr_node = trail_nodes[i]
		
		if prev_node.visible:
			curr_node.global_position = prev_node.global_position
			curr_node.global_rotation = prev_node.global_rotation
			curr_node.visible = true
	
	# First trail node follows vehicle
	if trail_nodes.size() > 0:
		trail_nodes[0].global_position = global_position
		trail_nodes[0].global_rotation = global_rotation
		trail_nodes[0].visible = is_active


func _trigger_lane_sound(lane: int):
	"""Trigger sound for current lane"""
	if not trigger_sounds or not lane_sound_system:
		return
	
	# Play lane sound with modified volume
	if lane_sound_system.has_method("play_lane_with_volume"):
		lane_sound_system.play_lane_with_volume(lane, sound_volume_modifier)
	elif lane_sound_system.has_method("play_lane"):
		lane_sound_system.play_lane(lane)
	
	_log("Triggered sound for lane %d" % lane)


func _on_playback_started():
	"""Handle playback start"""
	is_active = true
	visible = true
	
	# Make trail visible
	if trail_enabled:
		for node in trail_nodes:
			node.visible = false  # Will become visible as vehicle moves
	
	emit_signal("playback_started")
	_log("Playback started - vehicle active")


func _on_playback_stopped():
	"""Handle playback stop"""
	is_active = false
	visible = false
	current_lane = -1
	
	# Hide trail
	if trail_enabled:
		for node in trail_nodes:
			node.visible = false
	
	# Stop any active sounds
	if trigger_sounds and lane_sound_system and lane_sound_system.has_method("stop_all_lanes"):
		lane_sound_system.stop_all_lanes()
	
	emit_signal("playback_stopped")
	_log("Playback stopped - vehicle hidden")


func _on_loop_completed(loop_count: int):
	"""Handle loop completion"""
	_log("Loop %d completed" % loop_count)
	
	# Could add visual effects or sound cues here
	if trigger_sounds:
		# Play a completion sound or effect
		pass


# Utility methods
func set_ghost_color(color: Color):
	"""Update ghost vehicle color"""
	ghost_color = color
	if visual_sprite:
		visual_sprite.modulate = ghost_color
	
	# Update trail colors
	for i in trail_nodes.size():
		var trail_sprite = trail_nodes[i]
		trail_sprite.modulate = ghost_color
		trail_sprite.modulate.a = ghost_alpha * (1.0 - float(i) / float(trail_length))


func set_loop_enabled(enabled: bool):
	"""Enable/disable looping"""
	path_player.loop_enabled = enabled


func set_playback_speed(speed: float):
	"""Set playback speed multiplier"""
	path_player.playback_speed = speed


func get_playback_progress() -> float:
	"""Get current playback progress"""
	return path_player.get_playback_progress()


func is_playing() -> bool:
	"""Check if currently playing"""
	return path_player.is_playing()


func get_current_lane() -> int:
	"""Get current lane"""
	return current_lane