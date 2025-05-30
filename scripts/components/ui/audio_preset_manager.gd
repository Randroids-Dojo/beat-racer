extends VBoxContainer

signal preset_loaded(preset_name: String)
signal preset_saved(preset_name: String)

const AudioPresetResource = preload("res://scripts/resources/audio_preset_resource.gd")

const PRESETS_DIR = "user://audio_presets/"
const DEFAULT_PRESETS = {
	"Default": {
		"Master": {"volume_db": 0.0, "muted": false, "soloed": false},
		"Melody": {"volume_db": -6.0, "muted": false, "soloed": false},
		"Bass": {"volume_db": -6.0, "muted": false, "soloed": false},
		"Percussion": {"volume_db": -6.0, "muted": false, "soloed": false},
		"SFX": {"volume_db": -6.0, "muted": false, "soloed": false}
	},
	"Ambient": {
		"Master": {"volume_db": 0.0, "muted": false, "soloed": false},
		"Melody": {"volume_db": -3.0, "muted": false, "soloed": false},
		"Bass": {"volume_db": -9.0, "muted": false, "soloed": false},
		"Percussion": {"volume_db": -12.0, "muted": false, "soloed": false},
		"SFX": {"volume_db": -9.0, "muted": false, "soloed": false}
	},
	"Energetic": {
		"Master": {"volume_db": 0.0, "muted": false, "soloed": false},
		"Melody": {"volume_db": -4.0, "muted": false, "soloed": false},
		"Bass": {"volume_db": -2.0, "muted": false, "soloed": false},
		"Percussion": {"volume_db": -3.0, "muted": false, "soloed": false},
		"SFX": {"volume_db": -6.0, "muted": false, "soloed": false}
	}
}

var _preset_list: ItemList
var _name_input: LineEdit
var _save_button: Button
var _load_button: Button
var _delete_button: Button
var _current_preset_name: String = ""

func _ready():
	_setup_ui()
	_ensure_presets_directory()
	_load_preset_list()

func _setup_ui():
	add_theme_constant_override("separation", 10)
	
	# Title
	var title = Label.new()
	title.text = "Presets"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	
	# Separator
	add_child(HSeparator.new())
	
	# Preset list
	_preset_list = ItemList.new()
	_preset_list.custom_minimum_size = Vector2(200, 150)
	_preset_list.item_selected.connect(_on_preset_selected)
	add_child(_preset_list)
	
	# Name input
	var name_container = HBoxContainer.new()
	add_child(name_container)
	
	var name_label = Label.new()
	name_label.text = "Name:"
	name_label.custom_minimum_size.x = 50
	name_container.add_child(name_label)
	
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Enter preset name"
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_input.text_changed.connect(_on_name_changed)
	name_container.add_child(_name_input)
	
	# Buttons
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 5)
	add_child(button_container)
	
	_save_button = Button.new()
	_save_button.text = "Save"
	_save_button.disabled = true
	_save_button.pressed.connect(_on_save_pressed)
	button_container.add_child(_save_button)
	
	_load_button = Button.new()
	_load_button.text = "Load"
	_load_button.disabled = true
	_load_button.pressed.connect(_on_load_pressed)
	button_container.add_child(_load_button)
	
	_delete_button = Button.new()
	_delete_button.text = "Delete"
	_delete_button.disabled = true
	_delete_button.pressed.connect(_on_delete_pressed)
	button_container.add_child(_delete_button)
	
	# Default presets button
	var defaults_button = Button.new()
	defaults_button.text = "Reset to Default"
	defaults_button.pressed.connect(_on_reset_to_default)
	add_child(defaults_button)

func _ensure_presets_directory():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("audio_presets"):
		dir.make_dir("audio_presets")

func _load_preset_list():
	_preset_list.clear()
	
	# Add default presets
	for preset_name in DEFAULT_PRESETS:
		_preset_list.add_item("⭐ " + preset_name)
	
	# Add separator
	_preset_list.add_item("───────────────")
	var separator_idx = _preset_list.get_item_count() - 1
	_preset_list.set_item_disabled(separator_idx, true)
	_preset_list.set_item_selectable(separator_idx, false)
	
	# Add saved presets
	var dir = DirAccess.open(PRESETS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var preset_name = file_name.replace(".tres", "")
				_preset_list.add_item(preset_name)
			file_name = dir.get_next()

func _save_preset(preset_name: String):
	var preset = AudioPresetResource.new()
	preset.preset_name = preset_name
	preset.save_from_audio_manager()
	
	var file_path = PRESETS_DIR + preset_name + ".tres"
	var result = ResourceSaver.save(preset, file_path)
	
	if result == OK:
		print("Saved preset: " + preset_name)
		preset_saved.emit(preset_name)
		_load_preset_list()
		
		# Select the saved preset
		for i in range(_preset_list.get_item_count()):
			if _preset_list.get_item_text(i) == preset_name:
				_preset_list.select(i)
				_on_preset_selected(i)
				break
	else:
		push_error("Failed to save preset: " + preset_name)

func _load_preset(preset_name: String):
	# Check if it's a default preset
	if preset_name.begins_with("⭐ "):
		var default_name = preset_name.replace("⭐ ", "")
		if default_name in DEFAULT_PRESETS:
			_apply_default_preset(default_name)
			preset_loaded.emit(default_name)
			return
	
	# Load saved preset
	var file_path = PRESETS_DIR + preset_name + ".tres"
	if ResourceLoader.exists(file_path):
		var preset = ResourceLoader.load(file_path) as AudioPresetResource
		if preset:
			preset.apply_to_audio_manager()
			preset_loaded.emit(preset_name)
			print("Loaded preset: " + preset_name)
		else:
			push_error("Failed to load preset: " + preset_name)

func _apply_default_preset(preset_name: String):
	var preset_data = DEFAULT_PRESETS[preset_name]
	for bus_name in preset_data:
		var bus_settings = preset_data[bus_name]
		AudioManager.set_bus_volume_db(bus_name, bus_settings["volume_db"])
		AudioManager.set_bus_mute(bus_name, bus_settings["muted"])
		AudioManager.set_bus_solo(bus_name, bus_settings["soloed"])

func _delete_preset(preset_name: String):
	var file_path = PRESETS_DIR + preset_name + ".tres"
	var dir = DirAccess.open(PRESETS_DIR)
	if dir and dir.file_exists(preset_name + ".tres"):
		dir.remove(preset_name + ".tres")
		print("Deleted preset: " + preset_name)
		_load_preset_list()

func _on_preset_selected(index: int):
	var preset_name = _preset_list.get_item_text(index)
	
	# Check if separator
	if preset_name == "───────────────":
		return
	
	_current_preset_name = preset_name
	_name_input.text = preset_name.replace("⭐ ", "")
	_load_button.disabled = false
	_delete_button.disabled = preset_name.begins_with("⭐ ")  # Can't delete defaults

func _on_name_changed(text: String):
	_save_button.disabled = text.strip_edges().is_empty()

func _on_save_pressed():
	var preset_name = _name_input.text.strip_edges()
	if not preset_name.is_empty():
		_save_preset(preset_name)

func _on_load_pressed():
	if not _current_preset_name.is_empty():
		_load_preset(_current_preset_name)

func _on_delete_pressed():
	if not _current_preset_name.is_empty() and not _current_preset_name.begins_with("⭐ "):
		_delete_preset(_current_preset_name)

func _on_reset_to_default():
	_apply_default_preset("Default")
	preset_loaded.emit("Default")