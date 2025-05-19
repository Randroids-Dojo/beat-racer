# Rhythm-enhanced vehicle with beat-synchronized mechanics
extends Vehicle
class_name RhythmVehicle

@export_group("Rhythm Mechanics")
@export var boost_on_beat := true
@export var boost_power := 200.0  # Extra acceleration on beat
@export var beat_window := 0.15  # Time window for beat detection (seconds)
@export var visual_beat_response := true
@export var audio_on_beat := true
@export var boost_duration := 0.3  # How long the boost lasts

@export_group("Audio")
@export var boost_sound_bus := "SFX"
@export var boost_frequency := 440.0
@export var boost_volume := -12.0

signal beat_hit(beat_number: int, perfect: bool)
signal beat_missed(beat_number: int)
signal boost_applied(power: float)

var beat_manager: Node = null
var audio_manager: Node = null
var current_boost := 0.0
var boost_timer := 0.0
var beat_cooldown := 0.0
var last_beat_time := 0.0
var perfect_beats := 0
var total_beats := 0
var beat_accuracy := 0.0
var sound_generator: Node = null


func _ready() -> void:
	super._ready()
	
	# Get autoloads
	beat_manager = get_node("/root/BeatManager")
	audio_manager = get_node("/root/AudioManager")
	
	# Connect to beat signals
	if beat_manager:
		beat_manager.beat_occurred.connect(_on_beat_occurred)
		beat_manager.measure_completed.connect(_on_measure_completed)
	
	# Setup visual indicator
	if visual_beat_response:
		set_notify_transform(true)  # Enable transform notifications for visual feedback


func _physics_process(delta: float) -> void:
	# Update boost timer
	if boost_timer > 0:
		boost_timer -= delta
		if boost_timer <= 0:
			current_boost = 0.0
	
	# Update beat cooldown
	if beat_cooldown > 0:
		beat_cooldown -= delta
	
	# Apply boost to acceleration
	var original_accel = acceleration
	if current_boost > 0:
		acceleration += current_boost
	
	# Call parent physics process
	super._physics_process(delta)
	
	# Restore original acceleration
	acceleration = original_accel
	
	# Check for rhythm input
	if boost_on_beat:
		check_rhythm_input()


func check_rhythm_input() -> void:
	"""Check if player input aligns with beat"""
	# Only check when accelerating
	if throttle_input <= 0:
		return
	
	# Check if we're within beat window
	if beat_manager:
		var time_to_beat = beat_manager.get_time_to_next_beat()
		var time_since_beat = beat_manager.beat_duration - time_to_beat
		
		# Check if we're close to a beat (before or after)
		var within_window = (time_to_beat <= beat_window or time_since_beat <= beat_window)
		
		if within_window and beat_cooldown <= 0:
			# Prevent multiple boosts per beat
			beat_cooldown = beat_manager.beat_duration * 0.5
			
			# Calculate accuracy (0 = perfect, 1 = edge of window)
			var accuracy = min(time_to_beat, time_since_beat) / beat_window
			var perfect = accuracy < 0.3  # 30% of window is "perfect"
			
			apply_beat_boost(perfect)
			emit_signal("beat_hit", beat_manager.current_beat, perfect)
			
			if perfect:
				perfect_beats += 1
			total_beats += 1
			beat_accuracy = float(perfect_beats) / float(total_beats)


func apply_beat_boost(perfect: bool) -> void:
	"""Apply speed boost when hitting a beat"""
	var boost_amount = boost_power
	if perfect:
		boost_amount *= 1.5  # 50% extra for perfect timing
	
	current_boost = boost_amount
	boost_timer = boost_duration
	
	emit_signal("boost_applied", boost_amount)
	
	# Visual feedback
	if visual_beat_response:
		apply_visual_feedback(perfect)
	
	# Audio feedback
	if audio_on_beat:
		play_boost_sound(perfect)


func apply_visual_feedback(perfect: bool) -> void:
	"""Apply visual effects on beat"""
	# Scale pulse
	var tween = create_tween()
	var scale_amount = 1.2 if perfect else 1.1
	tween.tween_property(self, "scale", Vector2(scale_amount, scale_amount), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	
	# Color flash (requires modulate property)
	var flash_color = Color(1.5, 1.5, 1.5) if perfect else Color(1.2, 1.2, 1.2)
	tween.parallel().tween_property(self, "modulate", flash_color, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func play_boost_sound(perfect: bool) -> void:
	"""Play boost sound effect"""
	var frequency = boost_frequency
	if perfect:
		frequency *= 1.5  # Higher pitch for perfect
	
	# Create a simple tone using AudioStreamGenerator
	var player = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 0.1
	
	player.stream = stream
	player.bus = boost_sound_bus
	player.volume_db = boost_volume
	add_child(player)
	
	# Generate the tone
	player.play()
	var playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	
	if playback:
		var sample_rate = stream.mix_rate
		var duration = 0.2
		var samples = int(sample_rate * duration)
		
		for i in range(samples):
			var t = float(i) / sample_rate
			var value = sin(2.0 * PI * frequency * t)
			
			# Apply simple envelope
			var envelope = 1.0
			if t < 0.01:  # Attack
				envelope = t / 0.01
			elif t > duration - 0.1:  # Release
				envelope = (duration - t) / 0.1
			
			value *= envelope * 0.3  # Reduce volume
			playback.push_frame(Vector2(value, value))
	
	# Remove player after sound completes
	player.finished.connect(player.queue_free)


func _draw() -> void:
	"""Enhanced drawing with rhythm indicators"""
	super._draw()
	
	# Draw boost indicator
	if current_boost > 0:
		var boost_percent = current_boost / boost_power
		var boost_color = Color(1, 0.5, 0, 0.8)  # Orange
		
		# Draw boost trail
		var trail_length = vehicle_length * boost_percent
		draw_rect(Rect2(-trail_length, -vehicle_width/2, trail_length, vehicle_width), 
				 boost_color, false, 2.0)
		
		# Draw boost particles (simple circles)
		for i in range(3):
			var offset = Vector2(-vehicle_length/2 - i * 10, randf_range(-vehicle_width/2, vehicle_width/2))
			draw_circle(offset, 3.0, boost_color)


func get_rhythm_stats() -> Dictionary:
	"""Get rhythm performance statistics"""
	return {
		"perfect_beats": perfect_beats,
		"total_beats": total_beats,
		"accuracy": beat_accuracy,
		"current_boost": current_boost,
		"boost_active": boost_timer > 0
	}


func reset_rhythm_stats() -> void:
	"""Reset rhythm statistics"""
	perfect_beats = 0
	total_beats = 0
	beat_accuracy = 0.0


func _on_beat_occurred(beat_number: int) -> void:
	"""Handle beat occurrence for visual/audio cues"""
	# Add subtle visual pulse even without input
	if visual_beat_response and current_speed > 10:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.05, 1.05, 1.05), 0.05)
		tween.tween_property(self, "modulate", Color.WHITE, 0.1)


func _on_measure_completed(measure_number: int) -> void:
	"""Handle measure completion for special effects"""
	# Could add measure-based mechanics here
	pass
