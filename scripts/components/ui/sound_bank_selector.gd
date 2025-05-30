extends VBoxContainer
class_name SoundBankSelector

signal bank_selected(bank_name: String)
signal bank_saved(bank_name: String)
signal bank_deleted(bank_name: String)

const SoundBankManager = preload("res://scripts/components/sound/sound_bank_manager.gd")

var _bank_manager: SoundBankManager
var _bank_list: ItemList
var _bank_name_input: LineEdit
var _current_bank_label: Label
var _bank_description_label: Label
var _save_button: Button
var _delete_button: Button
var _prev_button: Button
var _next_button: Button
var _generator_info_label: Label

func _ready():
	_setup_ui()

func set_bank_manager(bank_manager: SoundBankManager):
	"""Set the sound bank manager reference"""
	print("SoundBankSelector: Setting bank manager: %s" % str(bank_manager))
	
	if _bank_manager:
		# Disconnect old signals
		_bank_manager.bank_changed.disconnect(_on_bank_changed)
		_bank_manager.bank_loaded.disconnect(_on_bank_loaded)
		_bank_manager.bank_saved.disconnect(_on_bank_saved)
	
	_bank_manager = bank_manager
	
	if _bank_manager:
		print("SoundBankSelector: Bank manager set, available banks: %s" % str(_bank_manager.get_available_banks()))
		
		# Connect signals
		_bank_manager.bank_changed.connect(_on_bank_changed)
		_bank_manager.bank_loaded.connect(_on_bank_loaded)
		_bank_manager.bank_saved.connect(_on_bank_saved)
		
		_refresh_bank_list()
		_update_current_bank_info()
	else:
		print("SoundBankSelector: Bank manager is null!")

func _setup_ui():
	add_theme_constant_override("separation", 10)
	
	# Title
	var title = Label.new()
	title.text = "Sound Banks"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	
	# Separator
	add_child(HSeparator.new())
	
	# Current bank info
	var current_container = VBoxContainer.new()
	current_container.add_theme_constant_override("separation", 5)
	add_child(current_container)
	
	var current_title = Label.new()
	current_title.text = "Current Bank:"
	current_title.add_theme_font_size_override("font_size", 14)
	current_container.add_child(current_title)
	
	_current_bank_label = Label.new()
	_current_bank_label.text = "None"
	_current_bank_label.add_theme_color_override("font_color", Color.CYAN)
	current_container.add_child(_current_bank_label)
	
	_bank_description_label = Label.new()
	_bank_description_label.text = ""
	_bank_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bank_description_label.custom_minimum_size.y = 40
	current_container.add_child(_bank_description_label)
	
	_generator_info_label = Label.new()
	_generator_info_label.text = ""
	_generator_info_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	current_container.add_child(_generator_info_label)
	
	# Navigation buttons
	var nav_container = HBoxContainer.new()
	nav_container.add_theme_constant_override("separation", 5)
	add_child(nav_container)
	
	_prev_button = Button.new()
	_prev_button.text = "← Previous"
	_prev_button.pressed.connect(_on_prev_bank)
	nav_container.add_child(_prev_button)
	
	_next_button = Button.new()
	_next_button.text = "Next →"
	_next_button.pressed.connect(_on_next_bank)
	nav_container.add_child(_next_button)
	
	# Separator
	add_child(HSeparator.new())
	
	# Bank list
	var list_title = Label.new()
	list_title.text = "Available Banks:"
	add_child(list_title)
	
	_bank_list = ItemList.new()
	_bank_list.custom_minimum_size = Vector2(250, 150)
	_bank_list.item_selected.connect(_on_bank_list_selected)
	add_child(_bank_list)
	
	# Bank name input
	var input_container = HBoxContainer.new()
	add_child(input_container)
	
	var input_label = Label.new()
	input_label.text = "Name:"
	input_label.custom_minimum_size.x = 50
	input_container.add_child(input_label)
	
	_bank_name_input = LineEdit.new()
	_bank_name_input.placeholder_text = "Enter bank name"
	_bank_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bank_name_input.text_changed.connect(_on_name_changed)
	input_container.add_child(_bank_name_input)
	
	# Action buttons
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 5)
	add_child(button_container)
	
	var load_button = Button.new()
	load_button.text = "Load"
	load_button.pressed.connect(_on_load_selected)
	button_container.add_child(load_button)
	
	_save_button = Button.new()
	_save_button.text = "Save Current"
	_save_button.disabled = true
	_save_button.pressed.connect(_on_save_current)
	button_container.add_child(_save_button)
	
	_delete_button = Button.new()
	_delete_button.text = "Delete"
	_delete_button.disabled = true
	_delete_button.pressed.connect(_on_delete_selected)
	button_container.add_child(_delete_button)
	
	# Generator controls
	add_child(HSeparator.new())
	
	var controls_title = Label.new()
	controls_title.text = "Generator Controls:"
	add_child(controls_title)
	
	var controls_container = HBoxContainer.new()
	controls_container.add_theme_constant_override("separation", 5)
	add_child(controls_container)
	
	var all_play_button = Button.new()
	all_play_button.text = "Play All"
	all_play_button.pressed.connect(_on_play_all)
	controls_container.add_child(all_play_button)
	
	var all_stop_button = Button.new()
	all_stop_button.text = "Stop All"
	all_stop_button.pressed.connect(_on_stop_all)
	controls_container.add_child(all_stop_button)
	
	# Bus controls
	var bus_controls = VBoxContainer.new()
	bus_controls.add_theme_constant_override("separation", 3)
	add_child(bus_controls)
	
	var buses = ["Melody", "Bass", "Percussion", "SFX"]
	for bus in buses:
		var bus_container = HBoxContainer.new()
		bus_container.add_theme_constant_override("separation", 5)
		bus_controls.add_child(bus_container)
		
		var bus_label = Label.new()
		bus_label.text = bus + ":"
		bus_label.custom_minimum_size.x = 80
		bus_container.add_child(bus_label)
		
		var bus_play = Button.new()
		bus_play.text = "Play"
		bus_play.custom_minimum_size.x = 50
		bus_play.pressed.connect(_on_bus_play.bind(bus))
		bus_container.add_child(bus_play)
		
		var bus_stop = Button.new()
		bus_stop.text = "Stop"
		bus_stop.custom_minimum_size.x = 50
		bus_stop.pressed.connect(_on_bus_stop.bind(bus))
		bus_container.add_child(bus_stop)

func _refresh_bank_list():
	"""Refresh the list of available banks"""
	if not _bank_manager or not _bank_list:
		return
	
	_bank_list.clear()
	var banks = _bank_manager.get_available_banks()
	
	for bank_name in banks:
		_bank_list.add_item(bank_name)
		
		# Highlight current bank
		if _bank_manager.get_current_bank_name() in bank_name:
			var item_count = _bank_list.get_item_count()
			_bank_list.set_item_custom_bg_color(item_count - 1, Color.DARK_BLUE)

func _update_current_bank_info():
	"""Update the display of current bank information"""
	if not _bank_manager or not _current_bank_label:
		return
	
	var info = _bank_manager.get_bank_info()
	if info.is_empty():
		_current_bank_label.text = "None"
		_bank_description_label.text = ""
		_generator_info_label.text = ""
		return
	
	_current_bank_label.text = info.get("name", "Unknown")
	_bank_description_label.text = info.get("description", "No description")
	
	var generator_count = info.get("generator_count", 0)
	var active_count = 0
	
	if _bank_manager:
		for gen in _bank_manager.get_generators():
			if gen._is_playing:
				active_count += 1
	
	_generator_info_label.text = "Generators: %d total, %d active" % [generator_count, active_count]

func _on_bank_list_selected(index: int):
	"""Handle bank selection from list"""
	var bank_name = _bank_list.get_item_text(index)
	_bank_name_input.text = bank_name.replace("⭐ ", "")
	
	# Enable/disable delete button
	_delete_button.disabled = bank_name.begins_with("⭐ ")

func _on_name_changed(text: String):
	"""Handle bank name input changes"""
	_save_button.disabled = text.strip_edges().is_empty()

func _on_load_selected():
	"""Load the selected bank"""
	var selected = _bank_list.get_selected_items()
	if selected.size() > 0:
		var bank_name = _bank_list.get_item_text(selected[0])
		if _bank_manager:
			_bank_manager.load_bank(bank_name)

func _on_save_current():
	"""Save current generator state as a new bank"""
	var bank_name = _bank_name_input.text.strip_edges()
	if not bank_name.is_empty() and _bank_manager:
		if _bank_manager.save_bank(bank_name):
			_refresh_bank_list()
			bank_saved.emit(bank_name)

func _on_delete_selected():
	"""Delete the selected bank"""
	var selected = _bank_list.get_selected_items()
	if selected.size() > 0:
		var bank_name = _bank_list.get_item_text(selected[0])
		if not bank_name.begins_with("⭐ ") and _bank_manager:
			if _bank_manager.delete_bank(bank_name):
				_refresh_bank_list()
				bank_deleted.emit(bank_name)

func _on_prev_bank():
	"""Switch to previous bank"""
	if _bank_manager:
		_bank_manager.switch_to_previous_bank()

func _on_next_bank():
	"""Switch to next bank"""
	if _bank_manager:
		_bank_manager.switch_to_next_bank()

func _on_play_all():
	"""Start all generators"""
	if _bank_manager:
		_bank_manager.set_all_generators_playing(true)
		_update_current_bank_info()

func _on_stop_all():
	"""Stop all generators"""
	if _bank_manager:
		_bank_manager.set_all_generators_playing(false)
		_update_current_bank_info()

func _on_bus_play(bus_name: String):
	"""Start generators on specific bus"""
	if _bank_manager:
		_bank_manager.set_bus_generators_playing(bus_name, true)
		_update_current_bank_info()

func _on_bus_stop(bus_name: String):
	"""Stop generators on specific bus"""
	if _bank_manager:
		_bank_manager.set_bus_generators_playing(bus_name, false)
		_update_current_bank_info()

func _on_bank_changed(bank_name: String):
	"""Handle bank change signal"""
	_update_current_bank_info()
	_refresh_bank_list()
	bank_selected.emit(bank_name)

func _on_bank_loaded(bank_name: String):
	"""Handle bank loaded signal"""
	_update_current_bank_info()

func _on_bank_saved(bank_name: String):
	"""Handle bank saved signal"""
	_refresh_bank_list()