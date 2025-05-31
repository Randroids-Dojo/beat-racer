extends Node
class_name EnhancedLaneSoundSystem

signal lane_changed(old_lane: int, new_lane: int)
signal sound_bank_changed(bank_name: String)
signal sound_triggered(lane: int, note: int)

const SoundBankManager = preload("res://scripts/components/sound/sound_bank_manager.gd")

enum LaneType {
	LEFT,
	CENTER, 
	RIGHT
}

const MAX_LANES = 3

var _sound_bank_manager: SoundBankManager
var _current_lane: int = LaneType.CENTER
var _is_active: bool = false
var _lane_mappings: Dictionary = {} # Maps lane indices to generator indices

# Input handling for bank switching
var _bank_switch_cooldown: float = 0.0
const BANK_SWITCH_DELAY = 0.5

func _ready():
	_setup_sound_bank_manager()
	_setup_lane_mappings()

func _setup_sound_bank_manager():
	_sound_bank_manager = SoundBankManager.new()
	_sound_bank_manager.name = "SoundBankManager"
	add_child(_sound_bank_manager)
	
	# Connect signals
	_sound_bank_manager.bank_changed.connect(_on_bank_changed)
	_sound_bank_manager.generators_updated.connect(_on_generators_updated)

func _setup_lane_mappings():
	# Map lanes to specific generators based on their bus assignments
	# LEFT lane -> First Melody generator
	# CENTER lane -> First Bass generator  
	# RIGHT lane -> Second Melody generator (or Percussion if not available)
	
	print("EnhancedLaneSoundSystem: Setting up lane mappings...")
	if _sound_bank_manager:
		# Use call_deferred to ensure sound bank manager is fully initialized
		call_deferred("_update_lane_mappings")
		print("EnhancedLaneSoundSystem: Deferred lane mapping update")
	else:
		print("EnhancedLaneSoundSystem: No sound bank manager!")

func _update_lane_mappings():
	"""Update which generators are assigned to which lanes"""
	_lane_mappings.clear()
	
	if not _sound_bank_manager:
		return
	
	var generators = _sound_bank_manager.get_generators()
	var melody_generators = []
	var bass_generators = []
	var percussion_generators = []
	
	# Sort generators by bus
	for i in range(generators.size()):
		var gen = generators[i]
		if gen:
			var bus = gen.get_bus()
			match bus:
				"Melody":
					melody_generators.append(i)
				"Bass":
					bass_generators.append(i)
				"Percussion":
					percussion_generators.append(i)
	
	# Assign lanes to generators
	if melody_generators.size() > 0:
		_lane_mappings[LaneType.LEFT] = melody_generators[0]
	
	if bass_generators.size() > 0:
		_lane_mappings[LaneType.CENTER] = bass_generators[0]
	
	if melody_generators.size() > 1:
		_lane_mappings[LaneType.RIGHT] = melody_generators[1]
	elif percussion_generators.size() > 0:
		_lane_mappings[LaneType.RIGHT] = percussion_generators[0]
	
	print("EnhancedLaneSoundSystem: Lane mappings updated: %s" % _lane_mappings)

func _process(delta):
	# Handle bank switching cooldown
	if _bank_switch_cooldown > 0:
		_bank_switch_cooldown -= delta
	
	# Handle input for bank switching during gameplay
	if _bank_switch_cooldown <= 0:
		if Input.is_action_just_pressed("ui_page_up"):
			_sound_bank_manager.switch_to_next_bank()
			_bank_switch_cooldown = BANK_SWITCH_DELAY
		elif Input.is_action_just_pressed("ui_page_down"):
			_sound_bank_manager.switch_to_previous_bank()
			_bank_switch_cooldown = BANK_SWITCH_DELAY

# Lane control methods
func set_current_lane(lane: int):
	if lane < 0 or lane >= MAX_LANES:
		push_error("Invalid lane index: " + str(lane))
		return
	
	if lane != _current_lane:
		var old_lane = _current_lane
		_current_lane = lane
		
		# Trigger note on the new lane
		if _is_active:
			_trigger_lane_note(lane)
		
		emit_signal("lane_changed", old_lane, lane)

func get_current_lane() -> int:
	return _current_lane

func start_playback():
	_is_active = true
	if _lane_mappings.has(_current_lane):
		_trigger_lane_note(_current_lane)

func stop_playback():
	_is_active = false
	# Stop all generators
	_sound_bank_manager.set_all_generators_playing(false)

func is_playing() -> bool:
	return _is_active

func _trigger_lane_note(lane: int, scale_degree: int = 1):
	"""Trigger a note on the generator assigned to this lane"""
	if not _lane_mappings.has(lane):
		return
	
	var generator_idx = _lane_mappings[lane]
	var generators = _sound_bank_manager.get_generators()
	
	if generator_idx >= 0 and generator_idx < generators.size():
		var generator = generators[generator_idx]
		if generator:
			# Set the note first
			generator.set_note_from_scale(scale_degree)
			
			# Restart playback to create a distinct note trigger
			if generator._is_playing:
				generator.stop_playback()
			generator.start_playback()
			
			emit_signal("sound_triggered", lane, scale_degree)

# Sound bank control methods
func load_sound_bank(bank_name: String) -> bool:
	"""Load a specific sound bank"""
	return _sound_bank_manager.load_bank(bank_name)

func get_current_bank_name() -> String:
	return _sound_bank_manager.get_current_bank_name()

func get_available_banks() -> Array:
	return _sound_bank_manager.get_available_banks()

func save_current_bank(bank_name: String) -> bool:
	"""Save current generator state as a new bank"""
	return _sound_bank_manager.save_bank(bank_name)

func switch_to_next_bank():
	_sound_bank_manager.switch_to_next_bank()

func switch_to_previous_bank():
	_sound_bank_manager.switch_to_previous_bank()

# Advanced lane triggering methods
func trigger_lane_note(lane: int, scale_degree: int = 1):
	"""Manually trigger a note on a specific lane"""
	_trigger_lane_note(lane, scale_degree)

func trigger_lane_chord(lane: int, scale_degrees: Array):
	"""Trigger multiple notes (chord) on a lane"""
	if not _lane_mappings.has(lane):
		return
	
	var generator_idx = _lane_mappings[lane]
	var generators = _sound_bank_manager.get_generators()
	
	if generator_idx >= 0 and generator_idx < generators.size():
		var base_generator = generators[generator_idx]
		if base_generator:
			# Use the base generator for the root note
			base_generator.set_note_from_scale(scale_degrees[0])
			if not base_generator._is_playing:
				base_generator.start_playback()
			
			# Use other available generators for additional notes
			for i in range(1, scale_degrees.size()):
				var additional_idx = (generator_idx + i) % generators.size()
				if additional_idx != generator_idx:
					var additional_gen = generators[additional_idx]
					if additional_gen:
						additional_gen.set_note_from_scale(scale_degrees[i])
						if not additional_gen._is_playing:
							additional_gen.start_playback()

func set_lane_scale_degree(lane: int, scale_degree: int):
	"""Set the default scale degree for a lane"""
	if _lane_mappings.has(lane):
		var generator_idx = _lane_mappings[lane]
		var generators = _sound_bank_manager.get_generators()
		
		if generator_idx >= 0 and generator_idx < generators.size():
			var generator = generators[generator_idx]
			if generator:
				generator.set_note_from_scale(scale_degree)

# Lane position mapping (0.0 = left, 1.0 = right)
func trigger_note_by_position(position: float, scale_degree: int = 1):
	"""Trigger note based on position across track (0.0 = left, 1.0 = right)"""
	var lane: int
	if position < 0.33:
		lane = LaneType.LEFT
	elif position < 0.67:
		lane = LaneType.CENTER
	else:
		lane = LaneType.RIGHT
	
	_trigger_lane_note(lane, scale_degree)

func modulate_lane_sound(lane: int, modulation: float):
	"""Apply modulation (detune) to a specific lane"""
	if _lane_mappings.has(lane):
		var generator_idx = _lane_mappings[lane]
		var generators = _sound_bank_manager.get_generators()
		
		if generator_idx >= 0 and generator_idx < generators.size():
			var generator = generators[generator_idx]
			if generator:
				var current_detune = generator.get_detune()
				generator.set_detune(current_detune + modulation)

# Bus control methods
func set_bus_active(bus_name: String, active: bool):
	"""Enable/disable all generators on a specific bus"""
	_sound_bank_manager.set_bus_generators_playing(bus_name, active)

func get_lane_bus(lane: int) -> String:
	"""Get the audio bus for a specific lane"""
	if _lane_mappings.has(lane):
		var generator_idx = _lane_mappings[lane]
		var generators = _sound_bank_manager.get_generators()
		
		if generator_idx >= 0 and generator_idx < generators.size():
			return generators[generator_idx].get_bus()
	
	return "Melody"

# Sound bank manager access
func get_sound_bank_manager() -> SoundBankManager:
	return _sound_bank_manager

# Signal handlers
func _on_bank_changed(bank_name: String):
	_update_lane_mappings()
	emit_signal("sound_bank_changed", bank_name)
	print("EnhancedLaneSoundSystem: Bank changed to '%s'" % bank_name)

func _on_generators_updated():
	_update_lane_mappings()

# Debug methods
func print_system_info():
	print("=== Enhanced Lane Sound System ===")
	print("Current Bank: %s" % get_current_bank_name())
	print("Current Lane: %d" % _current_lane)
	print("Active: %s" % str(_is_active))
	print("Lane Mappings: %s" % _lane_mappings)
	
	var generators = _sound_bank_manager.get_generators()
	print("Generators: %d total" % generators.size())
	for i in range(generators.size()):
		var gen = generators[i]
		print("  Generator %d: Bus=%s, Playing=%s" % [i, gen.get_bus(), str(gen._is_playing)])
	print("=================================")

# Input action configuration
func setup_input_actions():
	"""Setup input actions for bank switching. Call this if actions don't exist."""
	if not InputMap.has_action("ui_page_up"):
		var page_up = InputEventKey.new()
		page_up.keycode = KEY_PAGEUP
		InputMap.add_action("ui_page_up")
		InputMap.action_add_event("ui_page_up", page_up)
	
	if not InputMap.has_action("ui_page_down"):
		var page_down = InputEventKey.new()
		page_down.keycode = KEY_PAGEDOWN
		InputMap.add_action("ui_page_down")
		InputMap.action_add_event("ui_page_down", page_down)