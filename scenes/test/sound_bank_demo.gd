extends Control

const SoundBankManager = preload("res://scripts/components/sound/sound_bank_manager.gd")
const SoundBankSelector = preload("res://scripts/components/ui/sound_bank_selector.gd")

var sound_bank_manager: SoundBankManager
var sound_bank_selector: SoundBankSelector

# UI Elements
var main_container: VBoxContainer
var title_label: Label
var info_panel: VBoxContainer
var current_bank_label: Label
var generator_info_label: Label
var demo_controls: VBoxContainer
var lane_controls: HBoxContainer
var trigger_controls: VBoxContainer

# Demo state
var auto_play_timer: Timer
var is_auto_playing: bool = false
var current_scale_degree: int = 1
var beat_counter: int = 0

func _ready():
	print("STEP 1: Starting _ready()")
	_setup_ui()
	print("STEP 2: UI setup complete")
	
	await _setup_sound_systems()
	print("STEP 3: Sound systems setup complete")
	
	_setup_demo_controls()
	print("STEP 4: Demo controls setup complete")
	
	print("STEP 5: Sound Bank Demo started - Press keys to test!")

func _setup_ui():
	# Main container
	main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 15)
	add_child(main_container)
	
	# Title
	title_label = Label.new()
	title_label.text = "Sound Bank Demo - Story 017"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title_label)
	
	# Separator
	main_container.add_child(HSeparator.new())
	
	# Info panel
	info_panel = VBoxContainer.new()
	info_panel.add_theme_constant_override("separation", 5)
	main_container.add_child(info_panel)
	
	current_bank_label = Label.new()
	current_bank_label.text = "Current Bank: Loading..."
	current_bank_label.add_theme_font_size_override("font_size", 16)
	info_panel.add_child(current_bank_label)
	
	generator_info_label = Label.new()
	generator_info_label.text = "Generators: Loading..."
	info_panel.add_child(generator_info_label)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = """Controls:
• A/D - Previous/Next Bank
• Q/W/E - Trigger Left/Center/Right Lane
• 1-7 - Scale Degrees
• Space - Auto-play toggle
• PageUp/PageDown - Bank switching (in-game)"""
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_container.add_child(instructions)

func _setup_sound_systems():
	print("SOUND_SETUP 1: Starting sound systems setup")
	
	# Wait for autoloads to be ready
	print("SOUND_SETUP 2: Waiting for autoloads to initialize...")
	await get_tree().process_frame
	await get_tree().process_frame
	print("SOUND_SETUP 3: Autoload frames waited")
	
	# Check if AudioManager is available and has set up buses
	if AudioManager and AudioManager.has_method("get_bus_volume_db"):
		print("SOUND_SETUP 4: AudioManager is ready")
	else:
		print("SOUND_SETUP 4: Warning: AudioManager not ready or missing")
	
	# Create sound bank manager directly to avoid complexity
	print("SOUND_SETUP 5: Creating SoundBankManager...")
	sound_bank_manager = SoundBankManager.new()
	sound_bank_manager.name = "SoundBankManager"
	print("SOUND_SETUP 6: SoundBankManager instance created")
	
	add_child(sound_bank_manager)
	print("SOUND_SETUP 7: SoundBankManager added as child")
	
	print("SOUND_SETUP 8: Skipping ready signal wait, using timer instead...")
	
	# Wait a short time for initialization instead of waiting for ready signal
	await get_tree().create_timer(0.5).timeout
	
	print("SOUND_SETUP 9: Timer wait complete")
	
	# Wait additional frames to ensure full initialization
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("SOUND_SETUP 10: Additional frames waited")
	
	if not sound_bank_manager:
		push_error("SOUND_SETUP ERROR: Failed to get sound bank manager!")
		return
	
	print("SOUND_SETUP 11: Getting generators and banks...")
	var generators = sound_bank_manager.get_generators()
	var banks = sound_bank_manager.get_available_banks()
	
	print("SOUND_SETUP 12: Sound Bank Manager ready with %d generators" % generators.size())
	print("SOUND_SETUP 13: Available banks: %s" % str(banks))
	
	# Connect signals
	print("SOUND_SETUP 14: Connecting signals...")
	if sound_bank_manager.has_signal("bank_changed"):
		sound_bank_manager.bank_changed.connect(_on_bank_changed)
		print("SOUND_SETUP 15: bank_changed signal connected")
	if sound_bank_manager.has_signal("bank_loaded"):
		sound_bank_manager.bank_loaded.connect(_on_bank_loaded)
		print("SOUND_SETUP 16: bank_loaded signal connected")
	
	print("SOUND_SETUP 17: Sound systems setup complete")

func _setup_demo_controls():
	# Auto-play timer
	auto_play_timer = Timer.new()
	auto_play_timer.wait_time = 0.5
	auto_play_timer.timeout.connect(_on_auto_play_beat)
	add_child(auto_play_timer)
	
	# Demo controls container
	demo_controls = VBoxContainer.new()
	demo_controls.add_theme_constant_override("separation", 10)
	main_container.add_child(demo_controls)
	
	# Sound bank selector
	sound_bank_selector = SoundBankSelector.new()
	sound_bank_selector.set_bank_manager(sound_bank_manager)
	sound_bank_selector.custom_minimum_size = Vector2(300, 400)
	demo_controls.add_child(sound_bank_selector)
	
	# Lane controls
	var lane_title = Label.new()
	lane_title.text = "Lane Triggers:"
	demo_controls.add_child(lane_title)
	
	lane_controls = HBoxContainer.new()
	lane_controls.add_theme_constant_override("separation", 10)
	demo_controls.add_child(lane_controls)
	
	var lane_names = ["Left (Q)", "Center (W)", "Right (E)"]
	for i in range(3):
		var button = Button.new()
		button.text = lane_names[i]
		button.pressed.connect(_trigger_lane.bind(i))
		lane_controls.add_child(button)
	
	# Scale degree controls
	var scale_title = Label.new()
	scale_title.text = "Scale Degrees (1-7):"
	demo_controls.add_child(scale_title)
	
	trigger_controls = VBoxContainer.new()
	trigger_controls.add_theme_constant_override("separation", 5)
	demo_controls.add_child(trigger_controls)
	
	var scale_container = HBoxContainer.new()
	scale_container.add_theme_constant_override("separation", 5)
	trigger_controls.add_child(scale_container)
	
	for i in range(1, 8):
		var degree_button = Button.new()
		degree_button.text = str(i)
		degree_button.custom_minimum_size = Vector2(40, 40)
		degree_button.pressed.connect(_set_scale_degree.bind(i))
		scale_container.add_child(degree_button)
	
	# Auto-play control
	var auto_play_button = Button.new()
	auto_play_button.text = "Toggle Auto-Play (Space)"
	auto_play_button.pressed.connect(_toggle_auto_play)
	trigger_controls.add_child(auto_play_button)
	
	# Update UI now that everything is set up
	_update_info_display()

func _input(event):
	if event is InputEventKey and event.pressed and sound_bank_manager:
		match event.keycode:
			KEY_A:
				sound_bank_manager.switch_to_previous_bank()
			KEY_D:
				sound_bank_manager.switch_to_next_bank()
			KEY_Q:
				_trigger_lane(0) # Left
			KEY_W:
				_trigger_lane(1) # Center
			KEY_E:
				_trigger_lane(2) # Right
			KEY_1:
				_set_scale_degree(1)
			KEY_2:
				_set_scale_degree(2)
			KEY_3:
				_set_scale_degree(3)
			KEY_4:
				_set_scale_degree(4)
			KEY_5:
				_set_scale_degree(5)
			KEY_6:
				_set_scale_degree(6)
			KEY_7:
				_set_scale_degree(7)
			KEY_SPACE:
				_toggle_auto_play()

func _trigger_lane(lane: int):
	# Trigger sound using sound bank manager directly
	if sound_bank_manager:
		var generators = sound_bank_manager.get_generators()
		
		# Map lanes to different bus types for variety:
		# Lane 0 (Q): Melody (generator 0)
		# Lane 1 (W): Bass (generator 3) 
		# Lane 2 (E): Percussion (generator 5)
		var generator_index = -1
		match lane:
			0: generator_index = 0  # First Melody generator
			1: generator_index = 3  # First Bass generator
			2: generator_index = 5  # First Percussion generator
		
		if generator_index >= 0 and generator_index < generators.size():
			var generator = generators[generator_index]
			generator.set_note_from_scale(current_scale_degree)
			print("Triggering lane %d (generator %d) with scale degree %d" % [lane, generator_index, current_scale_degree])
			if not generator._is_playing:
				print("Starting playback for generator %d" % generator_index)
				generator.start_playback()
			else:
				print("Generator %d already playing" % generator_index)
			print("Generator %d playing state: %s" % [generator_index, generator._is_playing])
		else:
			print("Invalid generator index %d for lane %d" % [generator_index, lane])

func _set_scale_degree(degree: int):
	current_scale_degree = degree
	print("Scale degree set to: %d" % degree)

func _toggle_auto_play():
	is_auto_playing = !is_auto_playing
	if is_auto_playing:
		auto_play_timer.start()
		if sound_bank_manager:
			sound_bank_manager.set_all_generators_playing(true)
		print("Auto-play started")
	else:
		auto_play_timer.stop()
		if sound_bank_manager:
			sound_bank_manager.set_all_generators_playing(false)
		print("Auto-play stopped")

func _on_auto_play_beat():
	beat_counter += 1
	
	# Trigger different lanes and scale degrees in a pattern
	var lane = beat_counter % 3
	var scale_degree = ((beat_counter % 7) + 1)
	
	_trigger_lane(lane)
	
	# Change banks every 16 beats
	if beat_counter % 16 == 0 and sound_bank_manager:
		sound_bank_manager.switch_to_next_bank()

func _on_bank_changed(changed_bank_name: String):
	_update_info_display()
	print("Demo: Bank changed to '%s'" % changed_bank_name)

func _on_bank_loaded(bank_name: String):
	_update_info_display()
	print("Demo: Bank loaded '%s'" % bank_name)

func _on_sound_triggered(lane: int, note: int):
	var lane_names = ["Left", "Center", "Right"]
	var lane_name = lane_names[lane] if lane < lane_names.size() else "Unknown"
	print("Demo: Sound triggered - Lane: %s, Scale Degree: %d" % [lane_name, note])

func _on_lane_changed(old_lane: int, new_lane: int):
	var lane_names = ["Left", "Center", "Right"]
	var old_name = lane_names[old_lane] if old_lane < lane_names.size() else "Unknown"
	var new_name = lane_names[new_lane] if new_lane < lane_names.size() else "Unknown"
	print("Demo: Lane changed from %s to %s" % [old_name, new_name])

func _update_info_display():
	if not sound_bank_manager:
		return
	
	var bank_info = sound_bank_manager.get_bank_info()
	if bank_info.is_empty():
		current_bank_label.text = "Current Bank: None"
		generator_info_label.text = "Generators: 0"
		return
	
	current_bank_label.text = "Current Bank: %s" % bank_info.get("name", "Unknown")
	
	var generators = sound_bank_manager.get_generators()
	var active_count = 0
	var bus_counts = {}
	
	for gen in generators:
		if gen._is_playing:
			active_count += 1
		
		var bus = gen.get_bus()
		bus_counts[bus] = bus_counts.get(bus, 0) + 1
	
	var bus_info = ""
	for bus in bus_counts:
		bus_info += "%s(%d) " % [bus, bus_counts[bus]]
	
	generator_info_label.text = "Generators: %d total, %d active | Buses: %s" % [generators.size(), active_count, bus_info.strip_edges()]

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Clean up when closing
		if sound_bank_manager:
			sound_bank_manager.set_all_generators_playing(false)
		get_tree().quit()