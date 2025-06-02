extends Node2D
## Main game scene that integrates all Beat Racer systems with save/load functionality
##
## This is the primary gameplay scene that combines vehicle driving, sound generation,
## recording, playback, save/load functionality, and all UI elements into a cohesive experience.

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

# Save/Load system
var composition_save_system: CompositionSaveSystem

# Audio export system
var composition_recorder: CompositionRecorder
var export_dialog: ExportDialog

# For testing lane switching
var last_triggered_lane: int = -1
var lane_trigger_timer: float = 0.0


func _ready() -> void:
	print("=== MainGame _ready() started ===")
	await _setup_systems()
	_connect_signals()
	_initialize_game_state()
	print("=== MainGame _ready() completed ===")


func _setup_systems() -> void:
	# Setup save system
	_setup_save_system()
	
	# Setup audio export system
	_setup_audio_export()
	
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
	_setup_ui()


func _setup_save_system() -> void:
	composition_save_system = CompositionSaveSystem.new()
	composition_save_system.name = "CompositionSaveSystem"
	add_child(composition_save_system)
	
	composition_save_system.composition_saved.connect(_on_composition_saved)
	composition_save_system.composition_loaded.connect(_on_composition_loaded)


func _setup_audio_export() -> void:
	# Create composition recorder
	var recorder_script = preload("res://scripts/systems/composition_recorder.gd")
	composition_recorder = Node.new()
	composition_recorder.set_script(recorder_script)
	composition_recorder.name = "CompositionRecorder"
	add_child(composition_recorder)
	
	# Create export dialog
	export_dialog = preload("res://scenes/components/ui/export_dialog.tscn").instantiate()
	ui_layer.add_child(export_dialog)
	export_dialog.visible = false
	
	# Connect signals
	composition_recorder.recording_started.connect(_on_audio_recording_started)
	composition_recorder.recording_stopped.connect(_on_audio_recording_stopped)
	composition_recorder.composition_saved.connect(_on_audio_composition_saved)
	export_dialog.export_requested.connect(_on_export_dialog_confirmed)


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
	
	# Set player vehicle as tracked vehicle
	if enhanced_lane_sound_system.has_method("set_tracked_vehicle"):
		enhanced_lane_sound_system.set_tracked_vehicle(player_vehicle)
		print("Enhanced sound system tracking player vehicle")


func _setup_recording_systems() -> void:
	print("Setting up recording systems...")
	
	# Create lap recorder
	var recorder_script = preload("res://scripts/components/recording/lap_recorder.gd")
	lap_recorder = Node.new()
	lap_recorder.set_script(recorder_script)
	lap_recorder.name = "LapRecorder"
	add_child(lap_recorder)
	
	# Connect lap recorder signals
	if lap_recorder.has_signal("lap_completed"):
		lap_recorder.lap_completed.connect(_on_lap_completed)


func _setup_visual_feedback() -> void:
	print("Setting up visual feedback systems...")
	
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
	if camera_controller:
		# Start following player vehicle
		if camera_controller.has_method("set_target"):
			camera_controller.set_target(player_vehicle)
		camera_controller.enabled = true


func _setup_ui() -> void:
	if not game_ui_panel:
		print("WARNING: GameUIPanel not found!")
		return
	
	# Populate sound banks if available
	if sound_bank_manager and game_ui_panel.has_method("populate_sound_banks"):
		game_ui_panel.populate_sound_banks(sound_bank_manager)
	
	# Set initial BPM from BeatManager
	if beat_manager:
		var current_bpm = beat_manager.bpm
		# UI will update BeatManager when BPM changes


func _connect_signals() -> void:
	# Game state manager signals
	if game_state_manager:
		game_state_manager.mode_changed.connect(_on_mode_changed)
		game_state_manager.recording_started.connect(_on_recording_started)
		game_state_manager.recording_stopped.connect(_on_recording_stopped) 
		game_state_manager.playback_started.connect(_on_playback_started)
		game_state_manager.playback_stopped.connect(_on_playback_stopped)
		game_state_manager.layer_added.connect(_on_layer_added)
		game_state_manager.layer_removed.connect(_on_layer_removed)
	
	# UI signals
	if game_ui_panel:
		game_ui_panel.record_pressed.connect(_on_record_pressed)
		game_ui_panel.play_pressed.connect(_on_play_pressed)
		game_ui_panel.stop_pressed.connect(_on_stop_pressed)
		game_ui_panel.clear_pressed.connect(_on_clear_pressed)
		game_ui_panel.sound_bank_changed.connect(_on_sound_bank_changed)
		game_ui_panel.layer_removed.connect(_on_ui_layer_removed)
		
		# Save/Load signals
		if game_ui_panel.has_signal("save_requested"):
			game_ui_panel.save_requested.connect(_on_save_requested)
		if game_ui_panel.has_signal("load_requested"):
			game_ui_panel.load_requested.connect(_on_load_requested)
		if game_ui_panel.has_signal("composition_loaded"):
			game_ui_panel.composition_loaded.connect(_on_ui_composition_loaded)
		if game_ui_panel.has_signal("export_requested"):
			game_ui_panel.export_requested.connect(_on_export_requested)
	
	# Vehicle signals
	if player_vehicle:
		if player_vehicle.has_signal("lane_changed"):
			player_vehicle.lane_changed.connect(_on_vehicle_lane_changed)
		if player_vehicle.has_signal("position_changed"):
			player_vehicle.position_changed.connect(_on_vehicle_position_changed)
	
	# Beat manager signals
	if beat_manager:
		beat_manager.beat_occurred.connect(_on_beat_occurred)
		beat_manager.measure_completed.connect(_on_measure_completed)


func _initialize_game_state() -> void:
	# Start in LIVE mode
	if game_state_manager:
		game_state_manager.change_mode(game_state_manager.GameMode.LIVE)


func _on_mode_changed(new_mode: int) -> void:
	print("Game mode changed to: ", new_mode)
	
	# Update UI to reflect new mode
	if game_ui_panel and game_ui_panel.has_method("set_game_mode"):
		game_ui_panel.set_game_mode(new_mode)
	
	# Configure systems for new mode
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
	
	# Stop all playback vehicles
	_clear_playback_vehicles()
	
	# Camera follows player
	if camera_controller and camera_controller.has_method("set_target"):
		camera_controller.set_target(player_vehicle)


func _configure_recording_mode() -> void:
	# Keep player vehicle active
	if player_vehicle:
		player_vehicle.set_physics_process(true)
		player_vehicle.visible = true
	
	# Start lap recorder
	if lap_recorder and player_vehicle:
		lap_recorder.setup(player_vehicle, null, track_system)
		lap_recorder.start_recording()


func _configure_playback_mode() -> void:
	# Disable player vehicle
	if player_vehicle:
		player_vehicle.set_physics_process(false)
		player_vehicle.visible = false
	
	# Spawn playback vehicles for all layers
	_spawn_playback_vehicles()
	
	# Camera follows first playback vehicle
	if camera_controller and playback_vehicles.size() > 0:
		camera_controller.set_target(playback_vehicles[0])


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
	# Update UI indicators
	if game_ui_panel and game_ui_panel.has_method("show_recording_indicator"):
		game_ui_panel.show_recording_indicator(true)


func _on_recording_stopped() -> void:
	# Stop lap recorder
	if lap_recorder:
		var recording = lap_recorder.stop_recording()
		if recording and game_state_manager:
			# Recording is handled by game state manager
			# Also save to composition if we have one
			if game_ui_panel and game_ui_panel.has_method("add_layer_to_composition"):
				var layer_data = _create_layer_data_from_recording(recording, game_state_manager.recorded_layers.size() - 1)
				game_ui_panel.add_layer_to_composition(layer_data)
	
	# Update UI
	if game_ui_panel and game_ui_panel.has_method("show_recording_indicator"):
		game_ui_panel.show_recording_indicator(false)


func _create_layer_data_from_recording(recording: Resource, layer_index: int) -> CompositionResource.LayerData:
	var layer_data = CompositionResource.LayerData.new("Layer " + str(layer_index + 1), layer_index)
	
	# Convert recording samples to composition path samples
	if recording.has("samples"):
		for sample in recording.samples:
			var path_sample = CompositionResource.PathSample.new()
			path_sample.timestamp = sample.timestamp
			path_sample.position = sample.position
			path_sample.velocity = sample.velocity if sample.has("velocity") else 0.0
			path_sample.current_lane = sample.current_lane if sample.has("current_lane") else -1
			path_sample.beat_aligned = sample.beat_aligned if sample.has("beat_aligned") else false
			path_sample.measure_number = sample.measure_number if sample.has("measure_number") else 0
			path_sample.beat_in_measure = sample.beat_in_measure if sample.has("beat_in_measure") else 0
			layer_data.path_samples.append(path_sample)
	
	# Set layer properties
	layer_data.lap_count = recording.lap_count if recording.has("lap_count") else 1
	layer_data.color = game_ui_panel.layer_colors[layer_index % game_ui_panel.layer_colors.size()] if game_ui_panel else Color.WHITE
	
	return layer_data


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


# Save/Load handlers
func _on_save_requested() -> void:
	# The UI will handle showing the save dialog
	# We just need to make sure the current state is captured
	pass


func _on_load_requested() -> void:
	# The UI will handle showing the load browser
	pass


func _on_ui_composition_loaded(composition: CompositionResource) -> void:
	# Clear current state
	_on_clear_pressed()
	
	# Load layers from composition
	for layer_data in composition.layers:
		# Convert layer data back to recording format
		var recording = _create_recording_from_layer_data(layer_data)
		if recording and game_state_manager:
			game_state_manager.recorded_layers.append(recording)
			_on_layer_added(game_state_manager.recorded_layers.size() - 1)
	
	# Update BPM
	if beat_manager:
		beat_manager.bpm = composition.bpm


func _create_recording_from_layer_data(layer_data: CompositionResource.LayerData) -> Resource:
	# Create a recording resource that matches the lap recorder format
	var recording = Resource.new()
	recording.set_script(preload("res://scripts/components/recording/lap_recorder.gd").Recording)
	
	var samples = []
	for path_sample in layer_data.path_samples:
		var sample = {
			"timestamp": path_sample.timestamp,
			"position": path_sample.position,
			"velocity": path_sample.velocity,
			"current_lane": path_sample.current_lane,
			"beat_aligned": path_sample.beat_aligned,
			"measure_number": path_sample.measure_number,
			"beat_in_measure": path_sample.beat_in_measure
		}
		samples.append(sample)
	
	recording.set("samples", samples)
	recording.set("lap_count", layer_data.lap_count)
	recording.set("total_time", layer_data.path_samples[-1].timestamp if layer_data.path_samples.size() > 0 else 0.0)
	
	return recording


func _on_composition_saved(filepath: String, composition: CompositionResource) -> void:
	print("Composition saved: ", filepath)


func _on_composition_loaded(filepath: String, composition: CompositionResource) -> void:
	print("Composition loaded: ", filepath)


# UI callback handlers
func _on_record_pressed() -> void:
	if game_state_manager.can_record():
		game_state_manager.start_recording()
	else:
		# Could show a message that max layers reached
		pass


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


# Audio export handlers
func _on_export_requested() -> void:
	# Check if we have any layers to export
	if game_state_manager.recorded_layers.is_empty():
		if game_ui_panel:
			game_ui_panel.update_status("No layers to export!")
		return
	
	# Check if already recording audio
	if composition_recorder.is_recording:
		if game_ui_panel:
			game_ui_panel.update_status("Already recording audio!")
		return
	
	# Start audio recording of the playback
	_start_audio_export()


func _start_audio_export() -> void:
	# Get current composition details
	var composition_name = "Untitled"
	if game_ui_panel and game_ui_panel.has_method("create_composition_from_current_state"):
		var comp = game_ui_panel.create_composition_from_current_state()
		composition_name = comp.composition_name
	
	# Set sound bank info
	if sound_bank_manager:
		var current_bank = sound_bank_manager.get_current_bank_name()
		var bank_index = sound_bank_manager.get_current_bank_index()
		composition_recorder.set_sound_bank_info(current_bank, bank_index)
	
	# Start recording with metadata
	composition_recorder.start_composition_recording(composition_name, game_state_manager.recorded_layers)
	
	# Start playback if not already playing
	if game_state_manager.current_mode != game_state_manager.GameMode.PLAYBACK:
		game_state_manager.change_mode(game_state_manager.GameMode.PLAYBACK)
		game_state_manager.start_playback()
	
	if game_ui_panel:
		game_ui_panel.update_status("Recording audio for export...")
	
	# Set up a timer to stop recording after one full loop
	_setup_export_timer()


func _setup_export_timer() -> void:
	# Calculate how long one full loop takes
	var max_duration = 0.0
	for layer in game_state_manager.recorded_layers:
		if layer and layer.has("duration"):
			max_duration = max(max_duration, layer.duration)
	
	# Add a small buffer
	max_duration += 1.0
	
	# Create timer to stop recording
	var timer = Timer.new()
	timer.wait_time = max_duration
	timer.one_shot = true
	timer.timeout.connect(_on_export_timer_timeout)
	add_child(timer)
	timer.start()


func _on_export_timer_timeout() -> void:
	# Stop the audio recording
	var result = composition_recorder.stop_composition_recording()
	
	# Stop playback
	game_state_manager.stop_playback()
	
	# Show export dialog
	if result.has("audio") and result.audio:
		var duration = result.audio.get_length()
		var comp_name = result.metadata.get("track_name", "Untitled")
		export_dialog.setup(comp_name, duration)
		export_dialog.popup_centered()
	else:
		if game_ui_panel:
			game_ui_panel.update_status("Export failed - no audio recorded")


func _on_audio_recording_started() -> void:
	print("Audio recording started for export")


func _on_audio_recording_stopped(recording: AudioStreamWAV) -> void:
	print("Audio recording stopped. Duration: ", recording.get_length() if recording else 0)


func _on_audio_composition_saved(data: Dictionary) -> void:
	if data.has("audio_path"):
		print("Audio composition saved to: ", data.audio_path)
		if game_ui_panel:
			game_ui_panel.update_status("Exported: " + data.audio_path.get_file())


func _on_export_dialog_confirmed(options: Dictionary) -> void:
	# Export with the provided options
	var result = composition_recorder.export_with_options(options)
	
	if result.has("audio_path"):
		if game_ui_panel:
			game_ui_panel.update_status("Exported: " + result.audio_path.get_file())
		
		# Open folder if requested
		if options.get("open_folder", false):
			OS.shell_open(ProjectSettings.globalize_path("user://recordings/"))
	else:
		if game_ui_panel:
			game_ui_panel.update_status("Export failed!")