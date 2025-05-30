extends Node
class_name SoundBankManager

signal bank_changed(bank_name: String)
signal bank_loaded(bank_name: String)
signal bank_saved(bank_name: String)
signal generators_updated()

const SoundBankResource = preload("res://scripts/resources/sound_bank_resource.gd")
const SoundGenerator = preload("res://scripts/components/sound/sound_generator.gd")

const BANKS_DIR = "user://sound_banks/"
const MAX_GENERATORS = 8

var _current_bank_name: String = ""
var _current_bank: SoundBankResource
var _generators: Array = []
var _is_initialized: bool = false

func _ready():
	print("SoundBankManager._ready() starting...")
	_ensure_banks_directory()
	print("SoundBankManager: Banks directory ensured")
	_initialize_generators()
	print("SoundBankManager: Generators initialized")
	_load_default_bank()
	print("SoundBankManager._ready() complete")

func _ensure_banks_directory():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("sound_banks"):
		dir.make_dir("sound_banks")

func _initialize_generators():
	print("SoundBankManager: Starting generator initialization...")
	# Create default generators for different buses
	var bus_configs = [
		{"bus": "Melody", "count": 3},
		{"bus": "Bass", "count": 2},
		{"bus": "Percussion", "count": 2},
		{"bus": "SFX", "count": 1}
	]
	
	for bus_config in bus_configs:
		print("SoundBankManager: Creating %d generators for bus '%s'" % [bus_config["count"], bus_config["bus"]])
		for i in range(bus_config["count"]):
			print("SoundBankManager: Creating generator %d for bus '%s'" % [i, bus_config["bus"]])
			var generator = SoundGenerator.new(bus_config["bus"])
			print("SoundBankManager: Generator created, setting name...")
			generator.name = "Generator_%s_%d" % [bus_config["bus"], i]
			print("SoundBankManager: Adding generator as child...")
			add_child(generator)
			print("SoundBankManager: Generator added, appending to array...")
			_generators.append(generator)
			print("SoundBankManager: Generator %d for bus '%s' complete" % [i, bus_config["bus"]])
	
	_is_initialized = true
	print("SoundBankManager: Initialized %d generators" % _generators.size())

func _load_default_bank():
	print("SoundBankManager: Loading default bank 'Electronic'...")
	var result = load_bank("Electronic")
	print("SoundBankManager: Default bank load result: %s" % str(result))

func get_available_banks() -> Array:
	"""Get list of all available sound banks (default + saved)"""
	var banks: Array = []
	
	# Add default banks
	for bank_name in SoundBankResource.DEFAULT_BANKS:
		banks.append("⭐ " + bank_name)
	
	# Add saved banks
	var dir = DirAccess.open(BANKS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var bank_name = file_name.replace(".tres", "")
				banks.append(bank_name)
			file_name = dir.get_next()
	
	return banks

func get_current_bank_name() -> String:
	return _current_bank_name

func get_current_bank() -> SoundBankResource:
	return _current_bank

func get_generators() -> Array:
	return _generators

func load_bank(bank_name: String) -> bool:
	"""Load a sound bank by name"""
	print("SoundBankManager.load_bank() called with: %s" % bank_name)
	
	if not _is_initialized:
		push_error("SoundBankManager not initialized")
		return false
	
	print("SoundBankManager: Manager is initialized, proceeding...")
	var clean_name = bank_name.replace("⭐ ", "")
	print("SoundBankManager: Clean name: %s" % clean_name)
	
	var bank: SoundBankResource
	
	# Check if it's a default bank
	print("SoundBankManager: Checking if '%s' is in DEFAULT_BANKS..." % clean_name)
	if clean_name in SoundBankResource.DEFAULT_BANKS:
		print("SoundBankManager: Creating default bank '%s'..." % clean_name)
		bank = SoundBankResource.new().create_default_bank(clean_name)
		print("SoundBankManager: Default bank created: %s" % str(bank))
	else:
		# Load saved bank
		var file_path = BANKS_DIR + clean_name + ".tres"
		if ResourceLoader.exists(file_path):
			bank = ResourceLoader.load(file_path) as SoundBankResource
			print("SoundBankManager: Loading saved bank '%s'" % clean_name)
		else:
			push_error("Sound bank not found: " + clean_name)
			return false
	
	if not bank:
		push_error("Failed to load sound bank: " + clean_name)
		return false
	
	_apply_bank(bank)
	_current_bank_name = clean_name
	_current_bank = bank
	
	bank_loaded.emit(clean_name)
	bank_changed.emit(clean_name)
	generators_updated.emit()
	
	return true

func save_bank(bank_name: String) -> bool:
	"""Save current generator configuration as a new bank"""
	if not _is_initialized:
		push_error("SoundBankManager not initialized")
		return false
	
	var bank = SoundBankResource.new()
	bank.bank_name = bank_name
	bank.description = "Custom sound bank created " + Time.get_datetime_string_from_system()
	bank.save_current_generators(_generators)
	
	var file_path = BANKS_DIR + bank_name + ".tres"
	var result = ResourceSaver.save(bank, file_path)
	
	if result == OK:
		print("SoundBankManager: Saved bank '%s' with %d generators" % [bank_name, bank.get_generator_count()])
		bank_saved.emit(bank_name)
		return true
	else:
		push_error("Failed to save sound bank: " + bank_name)
		return false

func delete_bank(bank_name: String) -> bool:
	"""Delete a saved sound bank"""
	var clean_name = bank_name.replace("⭐ ", "")
	
	# Cannot delete default banks
	if clean_name in SoundBankResource.DEFAULT_BANKS:
		push_error("Cannot delete default bank: " + clean_name)
		return false
	
	var file_path = BANKS_DIR + clean_name + ".tres"
	var dir = DirAccess.open(BANKS_DIR)
	if dir and dir.file_exists(clean_name + ".tres"):
		dir.remove(clean_name + ".tres")
		print("SoundBankManager: Deleted bank '%s'" % clean_name)
		return true
	
	return false

func _apply_bank(bank: SoundBankResource):
	"""Apply a sound bank configuration to generators"""
	# Stop all generators first
	for gen in _generators:
		if gen._is_playing:
			gen.stop_playback()
	
	# Apply bank configuration
	bank.apply_to_generators(_generators)
	
	print("SoundBankManager: Applied bank '%s' to %d generators" % [bank.bank_name, _generators.size()])

func switch_to_next_bank():
	"""Switch to the next available bank"""
	var banks = get_available_banks()
	if banks.size() <= 1:
		return
	
	var current_index = banks.find("⭐ " + _current_bank_name)
	if current_index == -1:
		current_index = banks.find(_current_bank_name)
	
	if current_index != -1:
		var next_index = (current_index + 1) % banks.size()
		load_bank(banks[next_index])

func switch_to_previous_bank():
	"""Switch to the previous available bank"""
	var banks = get_available_banks()
	if banks.size() <= 1:
		return
	
	var current_index = banks.find("⭐ " + _current_bank_name)
	if current_index == -1:
		current_index = banks.find(_current_bank_name)
	
	if current_index != -1:
		var prev_index = (current_index - 1 + banks.size()) % banks.size()
		load_bank(banks[prev_index])

func get_generator_by_id(generator_id: String) -> SoundGenerator:
	"""Get a generator by its identifier"""
	for gen in _generators:
		if gen.name == generator_id:
			return gen
	return null

func get_generator_by_bus(bus_name: String) -> Array:
	"""Get all generators assigned to a specific bus"""
	var bus_generators: Array = []
	for gen in _generators:
		if gen.get_bus() == bus_name:
			bus_generators.append(gen)
	return bus_generators

func set_all_generators_playing(playing: bool):
	"""Start or stop all generators"""
	for gen in _generators:
		if playing and not gen._is_playing:
			gen.start_playback()
		elif not playing and gen._is_playing:
			gen.stop_playback()

func set_bus_generators_playing(bus_name: String, playing: bool):
	"""Start or stop all generators on a specific bus"""
	var bus_generators = get_generator_by_bus(bus_name)
	for gen in bus_generators:
		if playing and not gen._is_playing:
			gen.start_playback()
		elif not playing and gen._is_playing:
			gen.stop_playback()

func get_bank_info() -> Dictionary:
	"""Get information about the current bank"""
	if not _current_bank:
		return {}
	
	var info = {
		"name": _current_bank_name,
		"description": _current_bank.description,
		"generator_count": _current_bank.get_generator_count(),
		"creation_date": _current_bank.creation_date
	}
	
	return info

func create_bank_from_current() -> SoundBankResource:
	"""Create a new SoundBankResource from current generator state"""
	var bank = SoundBankResource.new()
	bank.save_current_generators(_generators)
	return bank

# Utility methods for quick generator control
func trigger_note(lane_position: float, scale_degree: int = 1):
	"""Trigger a note on generators based on lane position"""
	var generator_index = int(lane_position * _generators.size())
	generator_index = clamp(generator_index, 0, _generators.size() - 1)
	
	var gen = _generators[generator_index]
	if gen:
		gen.set_note_from_scale(scale_degree)
		if not gen._is_playing:
			gen.start_playback()

func modulate_generators(modulation_amount: float):
	"""Apply modulation to all active generators"""
	for gen in _generators:
		if gen._is_playing:
			var current_detune = gen.get_detune()
			gen.set_detune(current_detune + modulation_amount)