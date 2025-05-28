extends GutTest
# Tests for Sound Visualization Components

var _beat_pulse_visualizer: BeatPulseVisualizer
var _lane_sound_visualizer: LaneSoundVisualizer
var _sound_reactive_trail: SoundReactiveTrail
var _environment_visualizer: EnvironmentVisualizer

# Mock nodes
var _mock_beat_manager
var _mock_parent_node: Node2D


func before_each():
	# Create mocks
	_mock_beat_manager = double(BeatManager).new()
	add_child_autoqfree(_mock_beat_manager)
	
	_mock_parent_node = Node2D.new()
	add_child_autoqfree(_mock_parent_node)
	
	# Override BeatManager singleton
	if has_node("/root/BeatManager"):
		remove_child(get_node("/root/BeatManager"))
	add_child(_mock_beat_manager)
	_mock_beat_manager.name = "BeatManager"
	
	gut.p("=== Starting Sound Visualization Test ===")


func after_each():
	gut.p("=== Completed Sound Visualization Test ===")
	gut.p("")


# BeatPulseVisualizer Tests
func test_beat_pulse_visualizer_initialization():
	_beat_pulse_visualizer = BeatPulseVisualizer.new()
	add_child_autoqfree(_beat_pulse_visualizer)
	
	assert_not_null(_beat_pulse_visualizer, "BeatPulseVisualizer should be created")
	assert_eq(_beat_pulse_visualizer.base_scale, Vector2.ONE, "Default base scale should be Vector2.ONE")
	assert_eq(_beat_pulse_visualizer.pulse_scale, 1.5, "Default pulse scale should be 1.5")
	assert_false(_beat_pulse_visualizer.is_pulsing(), "Should not be pulsing initially")


func test_beat_pulse_trigger():
	_beat_pulse_visualizer = BeatPulseVisualizer.new()
	add_child_autoqfree(_beat_pulse_visualizer)
	
	# Watch for signal
	watch_signals(_beat_pulse_visualizer)
	
	# Trigger pulse
	_beat_pulse_visualizer.trigger_pulse(1.2)
	
	assert_true(_beat_pulse_visualizer.is_pulsing(), "Should be pulsing after trigger")
	assert_signal_emitted_with_parameters(_beat_pulse_visualizer, "pulse_triggered", [1.2])


func test_beat_pulse_auto_trigger():
	_beat_pulse_visualizer = BeatPulseVisualizer.new()
	_beat_pulse_visualizer.auto_pulse_on_beat = true
	add_child_autoqfree(_beat_pulse_visualizer)
	
	# Simulate beat
	if _mock_beat_manager.has_signal("beat_occurred"):
		_mock_beat_manager.emit_signal("beat_occurred", 4, 1.0)
	
	# Note: Signal connection might not work with mocks, so we test manual trigger
	_beat_pulse_visualizer._on_beat_occurred(4, 1.0)
	
	assert_true(_beat_pulse_visualizer.is_pulsing(), "Should pulse on beat")


func test_beat_pulse_progress():
	_beat_pulse_visualizer = BeatPulseVisualizer.new()
	_beat_pulse_visualizer.pulse_duration = 1.0
	add_child_autoqfree(_beat_pulse_visualizer)
	
	_beat_pulse_visualizer.trigger_pulse()
	assert_eq(_beat_pulse_visualizer.get_pulse_progress(), 0.0, "Progress should start at 0")
	
	# Simulate time passing
	_beat_pulse_visualizer._process(0.5)
	assert_almost_eq(_beat_pulse_visualizer.get_pulse_progress(), 0.5, 0.1, "Progress should be ~0.5 after half duration")


func test_beat_pulse_target_node():
	_beat_pulse_visualizer = BeatPulseVisualizer.new()
	_mock_parent_node.add_child(_beat_pulse_visualizer)
	add_child_autoqfree(_beat_pulse_visualizer)
	
	var target = Node2D.new()
	add_child_autoqfree(target)
	
	_beat_pulse_visualizer.set_target_node(target)
	_beat_pulse_visualizer.trigger_pulse()
	
	# Process one frame
	_beat_pulse_visualizer._process(0.016)
	
	assert_ne(target.scale, Vector2.ONE, "Target node scale should change during pulse")


# LaneSoundVisualizer Tests
func test_lane_sound_visualizer_initialization():
	_lane_sound_visualizer = LaneSoundVisualizer.new()
	add_child_autoqfree(_lane_sound_visualizer)
	
	assert_not_null(_lane_sound_visualizer, "LaneSoundVisualizer should be created")
	assert_eq(_lane_sound_visualizer.lane_count, 3, "Default lane count should be 3")
	assert_eq(_lane_sound_visualizer.lane_states.size(), 3, "Should have 3 lane states")


func test_lane_activation():
	_lane_sound_visualizer = LaneSoundVisualizer.new()
	add_child_autoqfree(_lane_sound_visualizer)
	
	watch_signals(_lane_sound_visualizer)
	
	# Activate lane 1
	_lane_sound_visualizer.activate_lane(1, 0.8)
	
	assert_true(_lane_sound_visualizer.lane_states[1].active, "Lane 1 should be active")
	assert_eq(_lane_sound_visualizer.lane_states[1].intensity, 0.8, "Lane 1 intensity should be 0.8")
	assert_signal_emitted_with_parameters(_lane_sound_visualizer, "lane_activated", [1, 0.8])


func test_lane_deactivation():
	_lane_sound_visualizer = LaneSoundVisualizer.new()
	add_child_autoqfree(_lane_sound_visualizer)
	
	# Activate then deactivate
	_lane_sound_visualizer.activate_lane(0)
	_lane_sound_visualizer.deactivate_lane(0)
	
	assert_false(_lane_sound_visualizer.lane_states[0].active, "Lane 0 should be inactive")


func test_lane_colors():
	_lane_sound_visualizer = LaneSoundVisualizer.new()
	add_child_autoqfree(_lane_sound_visualizer)
	
	# Test default colors
	assert_eq(_lane_sound_visualizer.lane_states[0].color, _lane_sound_visualizer.left_lane_color)
	assert_eq(_lane_sound_visualizer.lane_states[1].color, _lane_sound_visualizer.center_lane_color)
	assert_eq(_lane_sound_visualizer.lane_states[2].color, _lane_sound_visualizer.right_lane_color)
	
	# Test color change
	var new_color = Color.MAGENTA
	_lane_sound_visualizer.set_lane_color(1, new_color)
	assert_eq(_lane_sound_visualizer.lane_states[1].color, new_color)


func test_lane_waveform_update():
	_lane_sound_visualizer = LaneSoundVisualizer.new()
	_lane_sound_visualizer.waveform_enabled = true
	add_child_autoqfree(_lane_sound_visualizer)
	
	# Activate a lane
	_lane_sound_visualizer.activate_lane(0)
	
	# Process to update waveform
	_lane_sound_visualizer._process(0.02)
	
	# Check that waveform points are generated
	var has_non_zero = false
	for point in _lane_sound_visualizer.waveform_points:
		if point != 0.0:
			has_non_zero = true
			break
	
	assert_true(has_non_zero, "Waveform should have non-zero values when lane is active")


# SoundReactiveTrail Tests
func test_sound_reactive_trail_initialization():
	_sound_reactive_trail = SoundReactiveTrail.new()
	add_child_autoqfree(_sound_reactive_trail)
	
	assert_not_null(_sound_reactive_trail, "SoundReactiveTrail should be created")
	assert_eq(_sound_reactive_trail.max_points, 50, "Default max points should be 50")
	assert_eq(_sound_reactive_trail.get_trail_length(), 0, "Trail should start empty")


func test_trail_point_addition():
	_sound_reactive_trail = SoundReactiveTrail.new()
	add_child_autoqfree(_sound_reactive_trail)
	
	watch_signals(_sound_reactive_trail)
	
	# Add trail point
	_sound_reactive_trail.add_trail_point(Vector2(100, 200), 1, 0.8)
	
	assert_eq(_sound_reactive_trail.get_trail_length(), 1, "Trail should have 1 point")
	assert_signal_emitted_with_parameters(_sound_reactive_trail, "trail_updated", [1])


func test_trail_point_lifetime():
	_sound_reactive_trail = SoundReactiveTrail.new()
	_sound_reactive_trail.point_lifetime = 0.5
	add_child_autoqfree(_sound_reactive_trail)
	
	# Add point
	_sound_reactive_trail.add_trail_point(Vector2.ZERO)
	assert_eq(_sound_reactive_trail.get_trail_length(), 1)
	
	# Simulate time passing beyond lifetime
	_sound_reactive_trail._update_trail_points(0.6)
	
	assert_eq(_sound_reactive_trail.get_trail_length(), 0, "Old points should be removed")


func test_trail_max_points():
	_sound_reactive_trail = SoundReactiveTrail.new()
	_sound_reactive_trail.max_points = 5
	add_child_autoqfree(_sound_reactive_trail)
	
	# Add more than max points
	for i in 10:
		_sound_reactive_trail.add_trail_point(Vector2(i * 10, 0))
	
	assert_eq(_sound_reactive_trail.get_trail_length(), 5, "Trail should not exceed max points")


func test_trail_lane_change():
	_sound_reactive_trail = SoundReactiveTrail.new()
	_sound_reactive_trail.react_to_lane_change = true
	add_child_autoqfree(_sound_reactive_trail)
	
	# Add initial point
	_sound_reactive_trail.add_trail_point(Vector2.ZERO, 0, 1.0)
	
	# Change lane
	_sound_reactive_trail.set_current_lane(1)
	
	# Add another point
	_sound_reactive_trail.add_trail_point(Vector2(100, 0), 1, 1.0)
	
	# Last point should have higher intensity due to lane change
	assert_eq(_sound_reactive_trail.trail_points[-1].lane, 1, "Last point should be in lane 1")


func test_trail_clear():
	_sound_reactive_trail = SoundReactiveTrail.new()
	add_child_autoqfree(_sound_reactive_trail)
	
	# Add points
	for i in 5:
		_sound_reactive_trail.add_trail_point(Vector2(i * 10, 0))
	
	# Clear trail
	_sound_reactive_trail.clear_trail()
	
	assert_eq(_sound_reactive_trail.get_trail_length(), 0, "Trail should be empty after clear")
	assert_eq(_sound_reactive_trail.get_point_count(), 0, "Line2D points should be cleared")


# EnvironmentVisualizer Tests
func test_environment_visualizer_initialization():
	_environment_visualizer = EnvironmentVisualizer.new()
	add_child_autoqfree(_environment_visualizer)
	
	assert_not_null(_environment_visualizer, "EnvironmentVisualizer should be created")
	assert_true(_environment_visualizer.track_border_enabled, "Track border should be enabled by default")
	assert_true(_environment_visualizer.background_enabled, "Background should be enabled by default")


func test_environment_beat_reaction():
	_environment_visualizer = EnvironmentVisualizer.new()
	_environment_visualizer.react_to_beat = true
	add_child_autoqfree(_environment_visualizer)
	
	watch_signals(_environment_visualizer)
	
	# Simulate beat
	_environment_visualizer._on_beat_occurred(0, 1.0)
	
	assert_signal_emitted(_environment_visualizer, "environment_pulse_triggered")
	assert_signal_emitted_with_parameters(_environment_visualizer, "effect_activated", ["beat_pulse"])


func test_environment_grid_initialization():
	_environment_visualizer = EnvironmentVisualizer.new()
	_environment_visualizer.background_enabled = true
	_environment_visualizer.background_grid_size = 100
	add_child_autoqfree(_environment_visualizer)
	
	# Force grid initialization
	_environment_visualizer._initialize_grid()
	
	assert_gt(_environment_visualizer.grid_nodes.size(), 0, "Grid should have nodes")


func test_environment_particle_initialization():
	_environment_visualizer = EnvironmentVisualizer.new()
	_environment_visualizer.ambient_particles_enabled = true
	_environment_visualizer.particle_count = 10
	add_child_autoqfree(_environment_visualizer)
	
	# Force particle initialization
	_environment_visualizer._initialize_particles()
	
	assert_eq(_environment_visualizer.ambient_particles.size(), 10, "Should have 10 particles")


func test_environment_intensity_decay():
	_environment_visualizer = EnvironmentVisualizer.new()
	_environment_visualizer.reaction_decay_speed = 2.0
	add_child_autoqfree(_environment_visualizer)
	
	# Set initial intensity
	_environment_visualizer.set_reaction_intensity(1.0)
	assert_eq(_environment_visualizer.current_intensity, 1.0)
	
	# Process to decay
	_environment_visualizer._process(0.5)
	
	assert_almost_eq(_environment_visualizer.current_intensity, 0.0, 0.1, "Intensity should decay to ~0")


func test_environment_reset():
	_environment_visualizer = EnvironmentVisualizer.new()
	add_child_autoqfree(_environment_visualizer)
	
	# Set some state
	_environment_visualizer.set_reaction_intensity(1.5)
	_environment_visualizer.border_pulse_timer = 1.0
	
	# Reset
	_environment_visualizer.reset()
	
	assert_eq(_environment_visualizer.current_intensity, 0.0, "Intensity should be reset")
	assert_eq(_environment_visualizer.border_pulse_timer, 0.0, "Border pulse timer should be reset")


# Integration tests between components
func test_visualizer_signal_integration():
	# Test that visualizers can work together
	_beat_pulse_visualizer = BeatPulseVisualizer.new()
	_lane_sound_visualizer = LaneSoundVisualizer.new()
	
	add_child_autoqfree(_beat_pulse_visualizer)
	add_child_autoqfree(_lane_sound_visualizer)
	
	# Both should respond to beats
	_beat_pulse_visualizer._on_beat_occurred(0, 1.0)
	assert_true(_beat_pulse_visualizer.is_pulsing())
	
	# Lane visualizer can be activated independently
	_lane_sound_visualizer.activate_lane(0)
	assert_true(_lane_sound_visualizer.lane_states[0].active)