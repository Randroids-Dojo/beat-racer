extends Control
## Demo scene for testing the save/load system
##
## This scene provides an interactive interface to test all save/load functionality
## including creating, saving, loading, and managing compositions.

@onready var composition_browser: CompositionBrowser = $VBoxContainer/CompositionBrowser
@onready var create_button: Button = $VBoxContainer/TopBar/CreateButton
@onready var save_button: Button = $VBoxContainer/TopBar/SaveButton
@onready var autosave_button: Button = $VBoxContainer/TopBar/AutosaveButton
@onready var refresh_button: Button = $VBoxContainer/TopBar/RefreshButton

@onready var composition_info: RichTextLabel = $VBoxContainer/HSplitContainer/CompositionInfo
@onready var layer_list: ItemList = $VBoxContainer/HSplitContainer/LayerPanel/LayerList
@onready var add_layer_button: Button = $VBoxContainer/HSplitContainer/LayerPanel/AddLayerButton
@onready var remove_layer_button: Button = $VBoxContainer/HSplitContainer/LayerPanel/RemoveLayerButton

@onready var save_dialog: AcceptDialog = $SaveDialog
@onready var name_input: LineEdit = $SaveDialog/VBoxContainer/NameInput
@onready var author_input: LineEdit = $SaveDialog/VBoxContainer/AuthorInput
@onready var description_input: TextEdit = $SaveDialog/VBoxContainer/DescriptionInput

@onready var status_label: Label = $VBoxContainer/StatusBar/StatusLabel

var save_system: CompositionSaveSystem
var current_composition: CompositionResource
var has_changes: bool = false

func _ready() -> void:
	_setup_ui()
	_setup_save_system()
	_connect_signals()
	_create_new_composition()

func _setup_ui() -> void:
	# Configure save dialog
	save_dialog.title = "Save Composition"
	save_dialog.add_button("Cancel", true, "cancel")
	
	# Initial button states
	save_button.disabled = true
	remove_layer_button.disabled = true

func _setup_save_system() -> void:
	save_system = CompositionSaveSystem.new()
	add_child(save_system)
	
	save_system.composition_saved.connect(_on_composition_saved)
	save_system.composition_loaded.connect(_on_composition_loaded)
	save_system.save_error.connect(_on_save_error)
	save_system.load_error.connect(_on_load_error)

func _connect_signals() -> void:
	# Button signals
	create_button.pressed.connect(_on_create_pressed)
	save_button.pressed.connect(_on_save_pressed)
	autosave_button.pressed.connect(_on_autosave_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	add_layer_button.pressed.connect(_on_add_layer_pressed)
	remove_layer_button.pressed.connect(_on_remove_layer_pressed)
	
	# Layer list
	layer_list.item_selected.connect(_on_layer_selected)
	
	# Composition browser
	composition_browser.composition_selected.connect(_on_browser_composition_selected)
	composition_browser.composition_deleted.connect(_on_browser_composition_deleted)
	composition_browser.new_composition_requested.connect(_on_create_pressed)
	
	# Save dialog
	save_dialog.confirmed.connect(_on_save_dialog_confirmed)

func _create_new_composition() -> void:
	current_composition = CompositionResource.new()
	current_composition.composition_name = "New Composition"
	current_composition.author = OS.get_environment("USER")
	current_composition.bpm = 120.0
	has_changes = true
	_update_display()
	_update_status("Created new composition")

func _update_display() -> void:
	_update_composition_info()
	_update_layer_list()
	_update_button_states()

func _update_composition_info() -> void:
	if not current_composition:
		composition_info.text = "[i]No composition loaded[/i]"
		return
	
	var info_text = "[b]%s[/b]%s\n" % [
		current_composition.composition_name,
		" *" if has_changes else ""
	]
	info_text += "by %s\n\n" % current_composition.author
	
	info_text += "[b]Properties:[/b]\n"
	info_text += "• BPM: %.0f\n" % current_composition.bpm
	info_text += "• Duration: %s\n" % current_composition.get_formatted_duration()
	info_text += "• Layers: %d\n" % current_composition.get_layer_count()
	info_text += "• Created: %s\n" % current_composition.creation_date
	info_text += "• Modified: %s\n" % current_composition.modification_date
	
	if not current_composition.description.is_empty():
		info_text += "\n[b]Description:[/b]\n%s\n" % current_composition.description
	
	info_text += "\n[b]Audio Settings:[/b]\n"
	info_text += "• Sound Bank: %s\n" % current_composition.sound_bank_id
	
	composition_info.bbcode_text = info_text

func _update_layer_list() -> void:
	layer_list.clear()
	
	if not current_composition:
		return
	
	for i in range(current_composition.layers.size()):
		var layer = current_composition.layers[i]
		var item_text = "%s (samples: %d)" % [layer.layer_name, layer.path_samples.size()]
		layer_list.add_item(item_text)
		layer_list.set_item_custom_fg_color(i, layer.color)

func _update_button_states() -> void:
	save_button.disabled = not has_changes or not current_composition
	remove_layer_button.disabled = layer_list.get_selected_items().is_empty()

func _update_status(text: String) -> void:
	status_label.text = text

func _generate_test_layer() -> CompositionResource.LayerData:
	var layer = CompositionResource.LayerData.new()
	layer.layer_name = "Test Layer %d" % (current_composition.get_layer_count() + 1)
	layer.color = Color(randf(), randf(), randf())
	
	# Generate some test path samples
	var num_samples = randi_range(50, 200)
	var time_step = 0.1
	
	for i in range(num_samples):
		var sample = CompositionResource.PathSample.new()
		sample.timestamp = i * time_step
		sample.position = Vector2(
			sin(i * 0.1) * 200 + 400,
			cos(i * 0.1) * 150 + 300
		)
		sample.velocity = randf_range(30.0, 100.0)
		sample.current_lane = randi() % 3
		sample.beat_aligned = i % 4 == 0
		sample.measure_number = i / 16
		sample.beat_in_measure = i % 4
		
		layer.path_samples.append(sample)
	
	layer.lap_count = 1
	
	return layer

func _on_create_pressed() -> void:
	if has_changes:
		# Ask to save current composition first
		var dialog = ConfirmationDialog.new()
		dialog.dialog_text = "Save current composition before creating new?"
		dialog.confirmed.connect(_save_then_create)
		dialog.canceled.connect(_create_without_saving)
		add_child(dialog)
		dialog.popup_centered()
		dialog.popup_hide.connect(dialog.queue_free)
	else:
		_create_new_composition()

func _save_then_create() -> void:
	_on_save_pressed()
	# Create new after save completes
	await save_system.composition_saved
	_create_new_composition()

func _create_without_saving() -> void:
	_create_new_composition()

func _on_save_pressed() -> void:
	name_input.text = current_composition.composition_name
	author_input.text = current_composition.author
	description_input.text = current_composition.description
	save_dialog.popup_centered(Vector2(400, 300))

func _on_save_dialog_confirmed() -> void:
	current_composition.composition_name = name_input.text
	current_composition.author = author_input.text
	current_composition.description = description_input.text
	
	var filepath = save_system.save_composition(current_composition)
	if filepath:
		has_changes = false
		_update_display()

func _on_autosave_pressed() -> void:
	if current_composition:
		var filepath = save_system.autosave_composition(current_composition)
		if filepath:
			_update_status("Autosaved: " + filepath.get_file())

func _on_refresh_pressed() -> void:
	composition_browser.refresh_list()

func _on_add_layer_pressed() -> void:
	if current_composition:
		var layer = _generate_test_layer()
		current_composition.add_layer(layer)
		has_changes = true
		_update_display()
		_update_status("Added layer: " + layer.layer_name)

func _on_remove_layer_pressed() -> void:
	var selected = layer_list.get_selected_items()
	if selected.size() > 0 and current_composition:
		var index = selected[0]
		var layer_name = current_composition.layers[index].layer_name
		current_composition.remove_layer(index)
		has_changes = true
		_update_display()
		_update_status("Removed layer: " + layer_name)

func _on_layer_selected(index: int) -> void:
	_update_button_states()

func _on_browser_composition_selected(filepath: String, composition: CompositionResource) -> void:
	current_composition = composition
	has_changes = false
	_update_display()
	_update_status("Loaded: " + composition.composition_name)

func _on_browser_composition_deleted(filepath: String) -> void:
	_update_status("Deleted: " + filepath.get_file())

func _on_composition_saved(filepath: String, composition: CompositionResource) -> void:
	_update_status("Saved: " + filepath.get_file())
	composition_browser.refresh_list()

func _on_composition_loaded(filepath: String, composition: CompositionResource) -> void:
	_update_status("Loaded: " + filepath.get_file())

func _on_save_error(error_message: String) -> void:
	_update_status("Save Error: " + error_message)

func _on_load_error(error_message: String) -> void:
	_update_status("Load Error: " + error_message)