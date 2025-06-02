extends Node2D
## Main game scene that integrates all Beat Racer systems
##
## This is the primary gameplay scene that combines vehicle driving, sound generation,
## recording, playback, and all UI elements into a cohesive experience.

@onready var game_state_manager: Node = $GameStateManager
@onready var track_system: Node2D = $TrackSystem
@onready var vehicle_container: Node2D = $VehicleContainer
@onready var playback_container: Node2D = $PlaybackContainer
@onready var camera_controller: Camera2D = $CameraController
@onready var ui_layer: CanvasLayer = $UILayer
@onready var game_ui_panel: Control = $UILayer/GameUIPanel

# Core systems
@onready var beat_manager: Node = get_node("/root/BeatManager")
@onready var audio_manager: Node = get_node("/root/AudioManager")

# Vehicle references
var player_vehicle: Node2D
var playback_vehicles: Array[Node2D] = []

# Recording systems
var lap_recorder: Node
var path_players: Array[Node] = []

# Sound systems
var enhanced_lane_sound_system: Node
var sound_bank_manager: Node

# Visual feedback systems
var rhythm_feedback_manager: Node
var visual_effects_container: Node2D


func _ready() -> void:
	print("=== MainGame _ready() started ===")
	await _setup_systems()
	_connect_signals()
	_initialize_game_state()
	print("=== MainGame _ready() completed ===")


func _setup_systems() -> void:
	# Create player vehicle
	_spawn_player_vehicle()
	
	# Setup sound systems
	await _setup_sound_systems()
	
	# Setup recording systems
	_setup_recording_systems()
	
	# Setup visual feedback
	_setup_visual_feedback()
	
	# Configure camera
	_setup_camera()
	
	# Initialize UI
	await _setup_ui()


func _spawn_player_vehicle() -> void:
	print("Creating player vehicle...")
	# Create the enhanced vehicle 
	var EnhancedVehicle = preload("res://scripts/components/vehicle/enhanced_vehicle.gd")
	player_vehicle = CharacterBody2D.new()
	player_vehicle.set_script(EnhancedVehicle)
	player_vehicle.name = "PlayerVehicle"
	vehicle_container.add_child(player_vehicle)
	
	# Position at start line
	if track_system and track_system.has_method("get_start_position"):
		player_vehicle.position = track_system.get_start_position()
		print("Player vehicle positioned at: ", player_vehicle.position)
	else:
		player_vehicle.position = Vector2.ZERO
		print("Player vehicle positioned at origin")
	
	print("Player vehicle created successfully")


func _setup_sound_systems() -> void:
	print("Setting up sound systems...")
	
	# Create the enhanced lane sound system with sound bank support
	var enhanced_sound_script = preload("res://scripts/components/sound/enhanced_lane_sound_system.gd")
	enhanced_lane_sound_system = Node.new()
	enhanced_lane_sound_system.set_script(enhanced_sound_script)
	enhanced_lane_sound_system.name = "EnhancedLaneSoundSystem"
	add_child(enhanced_lane_sound_system)
	
	# Configure the sound system
	await enhanced_lane_sound_system.ready
	
	# Get the sound bank manager from the enhanced system
	if enhanced_lane_sound_system.has_method("get_sound_bank_manager"):
		sound_bank_manager = enhanced_lane_sound_system.get_sound_bank_manager()
		print("Sound bank manager acquired")
		
		# Wait for sound bank manager to be ready
		if sound_bank_manager:
			await sound_bank_manager.ready
			# Populate UI with available sound banks
			if game_ui_panel and game_ui_panel.has_method("populate_sound_banks"):
				game_ui_panel.populate_sound_banks(sound_bank_manager)
	
	# Set initial lane to center
	if enhanced_lane_sound_system.has_method("set_current_lane"):
		enhanced_lane_sound_system.set_current_lane(1)  # Center lane
		print("Initial lane set to center")
	
	print("Sound system setup complete")


func _setup_recording_systems() -> void:
	# Create lap recorder
	var recorder_script = preload("res://scripts/components/recording/lap_recorder.gd")
	lap_recorder = Node.new()
	lap_recorder.set_script(recorder_script)
	lap_recorder.name = "LapRecorder"
	add_child(lap_recorder)
	
	# Connect to track system
	if lap_recorder and track_system:
		lap_recorder.track_system = track_system


func _setup_visual_feedback() -> void:
	# Create visual effects container
	visual_effects_container = Node2D.new()
	visual_effects_container.name = "VisualEffects"
	add_child(visual_effects_container)
	
	# Create rhythm feedback manager
	var feedback_script = preload("res://scripts/components/visual/rhythm_feedback_manager.gd")
	rhythm_feedback_manager = Node.new()
	rhythm_feedback_manager.set_script(feedback_script)
	rhythm_feedback_manager.name = "RhythmFeedbackManager"
	visual_effects_container.add_child(rhythm_feedback_manager)


func _setup_camera() -> void:
	if camera_controller and player_vehicle:
		camera_controller.follow_target = player_vehicle
		camera_controller.current_mode = camera_controller.CameraMode.FOLLOW


func _setup_ui() -> void:
	print("Setting up UI...")
	print("game_ui_panel reference: ", game_ui_panel)
	
	# Wait for UI panel to be ready
	if game_ui_panel and not game_ui_panel.is_node_ready():
		print("Waiting for UI panel to be ready...")
		await game_ui_panel.ready
	
	# UI is already set up in the scene, just configure connections
	if game_ui_panel:
		print("Found game_ui_panel: ", game_ui_panel)
		# Connect UI events to game state manager
		if game_ui_panel.has_signal("record_pressed"):
			print("Connecting record_pressed signal")
			game_ui_panel.record_pressed.connect(_on_record_pressed)
		else:
			print("ERROR: game_ui_panel doesn't have record_pressed signal!")
		if game_ui_panel.has_signal("play_pressed"):
			game_ui_panel.play_pressed.connect(_on_play_pressed)
		if game_ui_panel.has_signal("stop_pressed"):
			game_ui_panel.stop_pressed.connect(_on_stop_pressed)
		if game_ui_panel.has_signal("clear_pressed"):
			game_ui_panel.clear_pressed.connect(_on_clear_pressed)
		if game_ui_panel.has_signal("sound_bank_changed"):
			game_ui_panel.sound_bank_changed.connect(_on_sound_bank_changed)
		if game_ui_panel.has_signal("layer_removed"):
			game_ui_panel.layer_removed.connect(_on_ui_layer_removed)


func _connect_signals() -> void:
	# Connect game state manager signals
	game_state_manager.mode_changed.connect(_on_mode_changed)
	game_state_manager.recording_started.connect(_on_recording_started)
	game_state_manager.recording_stopped.connect(_on_recording_stopped)
	game_state_manager.playback_started.connect(_on_playback_started)
	game_state_manager.playback_stopped.connect(_on_playback_stopped)
	game_state_manager.layer_added.connect(_on_layer_added)
	game_state_manager.layer_removed.connect(_on_layer_removed)
	
	# Connect beat manager signals
	if beat_manager:
		beat_manager.beat_occurred.connect(_on_beat_occurred)
		beat_manager.measure_completed.connect(_on_measure_completed)
	
	# Connect track system signals
	if track_system:
		if track_system.has_signal("lap_completed"):
			track_system.lap_completed.connect(_on_lap_completed)
	
	# Connect vehicle signals
	if player_vehicle:
		if player_vehicle.has_signal("lane_changed"):
			player_vehicle.lane_changed.connect(_on_vehicle_lane_changed)
		# Connect position updates for sound triggering
		if player_vehicle.has_signal("position_changed"):
			player_vehicle.position_changed.connect(_on_vehicle_position_changed)


func _initialize_game_state() -> void:
	# Start in live mode
	game_state_manager.change_mode(game_state_manager.GameMode.LIVE)
	
	# Start the beat
	if beat_manager:
		beat_manager.start()
	
	# Start processing for manual sound triggering
	set_process(true)


var last_triggered_lane = -1
var lane_trigger_timer = 0.0
const LANE_TRIGGER_INTERVAL = 0.5  # Trigger notes every 0.5 seconds

func _process(delta: float) -> void:
	# Update lane trigger timer
	lane_trigger_timer += delta
	# Manual sound triggering based on vehicle position
	if player_vehicle and enhanced_lane_sound_system and game_state_manager:
		# Only trigger sound in live mode or layering mode
		if game_state_manager.current_mode in [game_state_manager.GameMode.LIVE, game_state_manager.GameMode.LAYERING]:
			var lane_position = _calculate_lane_position(player_vehicle.position)
			
			# Trigger sound based on current lane position
			# Convert position to lane index for triggering with better distribution
			var lane_index: int
			if lane_position < 0.33:
				lane_index = 0  # Left lane
			elif lane_position < 0.67:
				lane_index = 1  # Center lane
			else:
				lane_index = 2  # Right lane
			
			# Trigger notes on interval or lane change
			if lane_index != last_triggered_lane or lane_trigger_timer >= LANE_TRIGGER_INTERVAL:
				if enhanced_lane_sound_system.has_method("trigger_lane_note"):
					enhanced_lane_sound_system.trigger_lane_note(lane_index)
					
					last_triggered_lane = lane_index
					lane_trigger_timer = 0.0


func _on_mode_changed(old_mode: int, new_mode: int) -> void:
	# Update UI to reflect mode change
	if game_ui_panel and game_ui_panel.has_method("set_game_mode"):
		game_ui_panel.set_game_mode(new_mode)
	
	# Configure systems based on mode
	match new_mode:
		game_state_manager.GameMode.LIVE:
			_configure_live_mode()
		game_state_manager.GameMode.RECORDING:
			_configure_recording_mode()
		game_state_manager.GameMode.PLAYBACK:
			_configure_playback_mode()
		game_state_manager.GameMode.LAYERING:
			_configure_layering_mode()


func _configure_live_mode() -> void:
	# Enable player vehicle
	if player_vehicle:
		player_vehicle.set_physics_process(true)
		player_vehicle.visible = true
	
	# Don't auto-start playback - let it be triggered by lane changes
	print("Live mode configured - sound will be triggered by lane changes")
	
	# Clear playback vehicles
	_clear_playback_vehicles()
	
	# Set camera to follow player
	if camera_controller:
		camera_controller.follow_target = player_vehicle


func _configure_recording_mode() -> void:
	# Keep live mode settings
	_configure_live_mode()
	
	# Start recording
	if lap_recorder and player_vehicle:
		lap_recorder.setup(player_vehicle, null, track_system)
		lap_recorder.start_recording()


func _configure_playback_mode() -> void:
	# Disable player vehicle physics (keep visible)
	if player_vehicle:
		player_vehicle.set_physics_process(false)
	
	# Disable live sound for player
	if enhanced_lane_sound_system and enhanced_lane_sound_system.has_method("stop_playback"):
		enhanced_lane_sound_system.stop_playback()
	
	# Spawn playback vehicles for all layers
	_spawn_playback_vehicles()
	
	# Set camera to overview mode
	if camera_controller:
		camera_controller.current_mode = camera_controller.CameraMode.OVERVIEW


func _configure_layering_mode() -> void:
	# Enable player vehicle
	if player_vehicle:
		player_vehicle.set_physics_process(true)
		player_vehicle.visible = true
	
	# Don't auto-start playback - let it be triggered by lane changes
	print("Layering mode configured - sound will be triggered by lane changes")
	
	# Keep playback vehicles running
	# Start recording for new layer
	if lap_recorder and player_vehicle:
		lap_recorder.setup(player_vehicle, null, track_system)
		lap_recorder.start_recording()


func _on_recording_started() -> void:
	print("Recording started - updating UI")
	# Update UI indicators
	if game_ui_panel:
		if game_ui_panel.has_method("show_recording_indicator"):
			game_ui_panel.show_recording_indicator(true)
		if game_ui_panel.has_method("update_status"):
			game_ui_panel.update_status("Recording in progress...")
		
		# Update record button
		var record_button = game_ui_panel.get_node_or_null("TopBar/RecordButton")
		if record_button:
			record_button.text = "Recording..."
			record_button.modulate = Color.RED
			record_button.disabled = true


func _on_recording_stopped() -> void:
	print("Recording stopped - updating UI")
	# Stop lap recorder
	if lap_recorder:
		var recording = lap_recorder.stop_recording()
		if recording and game_state_manager:
			# Recording is handled by game state manager
			pass
	
	# Update UI
	if game_ui_panel:
		if game_ui_panel.has_method("show_recording_indicator"):
			game_ui_panel.show_recording_indicator(false)
		if game_ui_panel.has_method("update_status"):
			game_ui_panel.update_status("Recording completed!")
		
		# Reset record button
		var record_button = game_ui_panel.get_node_or_null("TopBar/RecordButton")
		if record_button:
			record_button.text = "Add Layer"
			record_button.modulate = Color.WHITE  # Reset color
			record_button.disabled = false


func _on_playback_started() -> void:
	# Start all path players
	for player in path_players:
		if player and player.has_method("start_playback"):
			player.start_playback()


func _on_playback_stopped() -> void:
	# Stop all path players
	for player in path_players:
		if player and player.has_method("stop_playback"):
			player.stop_playback()


func _on_layer_added(layer_index: int) -> void:
	# Update UI layer list
	if game_ui_panel and game_ui_panel.has_method("add_layer_indicator"):
		game_ui_panel.add_layer_indicator(layer_index)


func _on_layer_removed(layer_index: int) -> void:
	# Update UI layer list
	if game_ui_panel and game_ui_panel.has_method("remove_layer_indicator"):
		game_ui_panel.remove_layer_indicator(layer_index)
	
	# Remove corresponding playback vehicle
	if layer_index < playback_vehicles.size():
		var vehicle = playback_vehicles[layer_index]
		playback_vehicles.remove_at(layer_index)
		vehicle.queue_free()


func _spawn_playback_vehicles() -> void:
	_clear_playback_vehicles()
	
	var layers = game_state_manager.recorded_layers
	for i in range(layers.size()):
		_spawn_playback_vehicle_for_layer(layers[i], i)


func _spawn_playback_vehicle_for_layer(recording: Resource, index: int) -> void:
	# Create playback vehicle
	var playback_scene = preload("res://scripts/components/vehicle/playback_vehicle.gd")
	var playback_vehicle = Node2D.new()
	playback_vehicle.set_script(playback_scene)
	playback_vehicle.name = "PlaybackVehicle" + str(index)
	playback_container.add_child(playback_vehicle)
	playback_vehicles.append(playback_vehicle)
	
	# Create path player for this vehicle
	var player_script = preload("res://scripts/components/playback/path_player.gd")
	var path_player = Node.new()
	path_player.set_script(player_script)
	path_player.name = "PathPlayer" + str(index)
	add_child(path_player)
	path_players.append(path_player)
	
	# Configure path player
	if path_player and recording:
		path_player.load_recording(recording)
		path_player.loop_enabled = true
		
		# Connect path player position updates to vehicle
		if path_player.has_signal("position_updated"):
			path_player.position_updated.connect(_on_playback_position_updated.bind(playback_vehicle))
		
		# Create sound system for playback vehicle
		var playback_sound_system = enhanced_lane_sound_system.duplicate()
		add_child(playback_sound_system)


func _clear_playback_vehicles() -> void:
	for vehicle in playback_vehicles:
		vehicle.queue_free()
	playback_vehicles.clear()
	
	for player in path_players:
		player.queue_free()
	path_players.clear()


func _on_beat_occurred(beat_number: int, beat_time: float) -> void:
	# Forward to visual feedback systems
	if rhythm_feedback_manager and rhythm_feedback_manager.has_method("on_beat"):
		rhythm_feedback_manager.on_beat()


func _on_measure_completed(measure_number: int, measure_time: float) -> void:
	# Could trigger special effects on measures
	pass


func _on_lap_completed() -> void:
	# Handle lap completion based on current mode
	match game_state_manager.current_mode:
		game_state_manager.GameMode.RECORDING, game_state_manager.GameMode.LAYERING:
			# Stop recording after one lap
			game_state_manager.stop_recording()


func _on_vehicle_lane_changed(new_lane: int) -> void:
	# Trigger sound for new lane
	if enhanced_lane_sound_system:
		enhanced_lane_sound_system.trigger_lane_note(new_lane)


func _on_vehicle_position_changed(new_position: Vector2) -> void:
	# Convert vehicle position to lane position for sound triggering
	if enhanced_lane_sound_system and track_system:
		# Calculate normalized lane position (0.0 = left, 1.0 = right)
		var lane_position = _calculate_lane_position(new_position)
		enhanced_lane_sound_system.trigger_note_by_position(lane_position)


func _calculate_lane_position(vehicle_position: Vector2) -> float:
	# Calculate lane position based on vehicle's position
	# For an oval track, we need to consider both X and Y coordinates
	# and the distance from the track center line
	
	var track_center = Vector2.ZERO  # Track center
	var lane_width = 100.0  # Width of each lane
	
	# Calculate distance from track center
	var distance_from_center = vehicle_position.distance_to(track_center)
	
	# For testing, use Y coordinate primarily (up/down movement)
	# This makes it easier to test lane switching by moving up/down
	var y_offset = vehicle_position.y
	var lane_range = 200.0  # Total range for all lanes
	
	# Normalize Y position to 0.0-1.0
	var normalized_position = (y_offset + lane_range/2) / lane_range
	
	# Clamp and return
	return clamp(normalized_position, 0.0, 1.0)


func _on_playback_position_updated(position: Vector2, rotation: float, lane: int, vehicle: Node2D) -> void:
	# Update playback vehicle position and rotation
	if vehicle:
		vehicle.position = position
		vehicle.rotation = rotation


# UI callback handlers
func _on_record_pressed() -> void:
	print("Record button pressed!")
	
	# Immediate visual feedback
	if game_ui_panel and game_ui_panel.has_method("update_status"):
		game_ui_panel.update_status("Record button clicked!")
	
	# Change button text immediately
	var record_button = game_ui_panel.get_node_or_null("TopBar/RecordButton") if game_ui_panel else null
	if record_button:
		print("Found record button, changing text...")
		record_button.text = "Recording..."
		record_button.modulate = Color.RED  # Make it red to show it's recording
		record_button.disabled = true
		print("Button text changed to: ", record_button.text)
	else:
		print("Could not find record button at TopBar/RecordButton")
	
	if not game_state_manager:
		print("ERROR: game_state_manager is null!")
		if game_ui_panel and game_ui_panel.has_method("update_status"):
			game_ui_panel.update_status("ERROR: Game state manager not found!")
		return
		
	if game_state_manager.can_record():
		print("Can record - starting recording...")
		if game_ui_panel and game_ui_panel.has_method("update_status"):
			game_ui_panel.update_status("Starting recording...")
		game_state_manager.start_recording()
	else:
		print("Cannot record - max layers reached or wrong mode")
		if game_ui_panel and game_ui_panel.has_method("update_status"):
			game_ui_panel.update_status("Cannot record - wrong mode or max layers reached")
		# Reset button if can't record
		if record_button:
			record_button.text = "Record"
			record_button.modulate = Color.WHITE
			record_button.disabled = false


func _on_play_pressed() -> void:
	game_state_manager.toggle_play_pause()


func _on_stop_pressed() -> void:
	match game_state_manager.current_mode:
		game_state_manager.GameMode.RECORDING, game_state_manager.GameMode.LAYERING:
			game_state_manager.stop_recording()
		game_state_manager.GameMode.PLAYBACK:
			game_state_manager.stop_playback()


func _on_clear_pressed() -> void:
	game_state_manager.clear_all_layers()
	if game_ui_panel and game_ui_panel.has_method("clear_all_layers"):
		game_ui_panel.clear_all_layers()


func _on_sound_bank_changed(bank_index: int) -> void:
	if sound_bank_manager:
		var available_banks = sound_bank_manager.get_available_banks()
		if bank_index >= 0 and bank_index < available_banks.size():
			var bank_name = available_banks[bank_index]
			print("Switching to sound bank: ", bank_name)
			sound_bank_manager.load_bank(bank_name)
		else:
			print("Invalid bank index: ", bank_index)


func _on_ui_layer_removed(layer_index: int) -> void:
	game_state_manager.remove_layer(layer_index)


func _input(event: InputEvent) -> void:
	# Global hotkeys
	if event.is_action_pressed("ui_cancel"):
		# ESC to stop recording or return to live mode
		match game_state_manager.current_mode:
			game_state_manager.GameMode.RECORDING, game_state_manager.GameMode.LAYERING:
				game_state_manager.stop_recording()
			game_state_manager.GameMode.PLAYBACK:
				game_state_manager.change_mode(game_state_manager.GameMode.LIVE)
	
	elif event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		# TAB to toggle camera mode
		if camera_controller:
			if camera_controller.current_mode == camera_controller.CameraMode.FOLLOW:
				camera_controller.current_mode = camera_controller.CameraMode.OVERVIEW
			else:
				camera_controller.current_mode = camera_controller.CameraMode.FOLLOW
	
	# Manual lane switching for testing (Q, W, E keys)
	elif event is InputEventKey and event.pressed:
		if enhanced_lane_sound_system:
			var lane_to_trigger = -1
			match event.keycode:
				KEY_Q:
					lane_to_trigger = 0  # Left lane
				KEY_W:
					lane_to_trigger = 1  # Center lane
				KEY_E:
					lane_to_trigger = 2  # Right lane
			
			if lane_to_trigger >= 0:
				if enhanced_lane_sound_system.has_method("trigger_lane_note"):
					enhanced_lane_sound_system.trigger_lane_note(lane_to_trigger)
					last_triggered_lane = lane_to_trigger
					lane_trigger_timer = 0.0
