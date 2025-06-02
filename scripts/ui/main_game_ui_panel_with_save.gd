extends Control
## Enhanced UI panel for the main game scene with save/load functionality
##
## This panel extends the main game UI with composition save/load features,
## allowing players to save their creations and load them later.

signal record_pressed()
signal play_pressed()
signal clear_pressed()
signal stop_pressed()
signal mode_changed(new_mode: int)
signal bpm_changed(new_bpm: float)
signal sound_bank_changed(bank_index: int)
signal layer_selected(layer_index: int)
signal layer_removed(layer_index: int)
signal camera_mode_changed()
signal save_requested()
signal load_requested()
signal composition_loaded(composition: CompositionResource)
signal export_requested()

# UI Component References
@onready var mode_label: Label = $TopBar/ModeLabel
@onready var bpm_slider: HSlider = $TopBar/BPMControl/BPMSlider
@onready var bpm_value: Label = $TopBar/BPMControl/BPMValue
@onready var record_button: Button = $TopBar/RecordButton
@onready var play_button: Button = $TopBar/PlayButton
@onready var stop_button: Button = $TopBar/StopButton
@onready var clear_button: Button = $TopBar/ClearButton
@onready var save_button: Button = $TopBar/SaveButton
@onready var load_button: Button = $TopBar/LoadButton
@onready var export_button: Button = $TopBar/ExportButton

@onready var sound_bank_selector: OptionButton = $LeftPanel/SoundBankSection/SoundBankSelector
@onready var layers_list: ItemList = $LeftPanel/LayersSection/LayersList
@onready var layer_remove_button: Button = $LeftPanel/LayersSection/RemoveLayerButton

@onready var status_label: Label = $BottomBar/StatusLabel
@onready var recording_indicator: Label = $BottomBar/RecordingIndicator
@onready var beat_counter_label: Label = $BottomBar/BeatCounter
@onready var composition_label: Label = $BottomBar/CompositionLabel

@onready var beat_viz_panel: PanelContainer = $RightPanel/BeatVisualizationPanel
@onready var audio_mixer_panel: Panel = $RightPanel/AudioMixerPanel

# Save/Load Components
@onready var composition_browser: CompositionBrowser = $CompositionBrowser
@onready var save_dialog: AcceptDialog = $SaveDialog
@onready var save_name_input: LineEdit = $SaveDialog/VBoxContainer/NameInput
@onready var save_author_input: LineEdit = $SaveDialog/VBoxContainer/AuthorInput
@onready var save_description_input: TextEdit = $SaveDialog/VBoxContainer/DescriptionInput

# State
var current_mode: int = 0  # GameMode.LIVE
var is_recording: bool = false
var is_playing: bool = false
var current_beat: int = 0
var current_measure: int = 0
var layer_colors: Array[Color] = [
	Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW,
	Color.MAGENTA, Color.CYAN, Color.ORANGE, Color.PURPLE
]

var current_composition: CompositionResource
var save_system: CompositionSaveSystem
var has_unsaved_changes: bool = false

# References
@onready var beat_manager: Node = get_node("/root/BeatManager")
@onready var audio_manager: Node = get_node("/root/AudioManager")


func _ready() -> void:
	_setup_save_system()
	_setup_ui()
	_connect_signals()
	_initialize_sound_banks()
	_update_ui_state()
	
	# Start with new composition
	_create_new_composition()


func _setup_save_system() -> void:
	save_system = CompositionSaveSystem.new()
	add_child(save_system)
	
	save_system.composition_saved.connect(_on_composition_saved)
	save_system.composition_loaded.connect(_on_composition_loaded)
	save_system.save_error.connect(_on_save_error)
	save_system.load_error.connect(_on_load_error)


func _setup_ui() -> void:
	# Configure BPM slider
	if bpm_slider:
		bpm_slider.min_value = 60
		bpm_slider.max_value = 240
		bpm_slider.step = 1
		bpm_slider.value = 120
		_update_bpm_display(120)
	
	# Configure layers list
	if layers_list:
		layers_list.max_columns = 1
		layers_list.select_mode = ItemList.SELECT_SINGLE
		layers_list.custom_minimum_size = Vector2(250, 200)
	
	# Initially hide recording indicator
	if recording_indicator:
		recording_indicator.visible = false
		recording_indicator.modulate = Color.RED
	
	# Configure buttons
	if stop_button:
		stop_button.visible = false  # Hidden initially
	
	# Hide composition browser initially
	if composition_browser:
		composition_browser.visible = false
	
	# Configure save dialog
	if save_dialog:
		save_dialog.title = "Save Composition"
		save_dialog.add_button("Cancel", true, "cancel")


func _connect_signals() -> void:
	# Button signals
	if record_button:
		record_button.pressed.connect(_on_record_pressed)
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if stop_button:
		stop_button.pressed.connect(_on_stop_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	if export_button:
		export_button.pressed.connect(_on_export_pressed)
	
	# BPM control
	if bpm_slider:
		bpm_slider.value_changed.connect(_on_bpm_changed)
	
	# Sound bank selector
	if sound_bank_selector:
		sound_bank_selector.item_selected.connect(_on_sound_bank_selected)
	
	# Layers list
	if layers_list:
		layers_list.item_selected.connect(_on_layer_selected)
	if layer_remove_button:
		layer_remove_button.pressed.connect(_on_remove_layer_pressed)
	
	# Beat manager signals
	if beat_manager:
		beat_manager.beat_occurred.connect(_on_beat_occurred)
		beat_manager.measure_completed.connect(_on_measure_completed)
	
	# Composition browser signals
	if composition_browser:
		composition_browser.composition_selected.connect(_on_browser_composition_selected)
		composition_browser.new_composition_requested.connect(_on_new_composition_requested)
		composition_browser.import_requested.connect(_on_import_requested)
		composition_browser.export_requested.connect(_on_export_requested)
	
	# Save dialog signals
	if save_dialog:
		save_dialog.confirmed.connect(_on_save_dialog_confirmed)


func _create_new_composition() -> void:
	current_composition = CompositionResource.new()
	current_composition.composition_name = "Untitled Composition"
	current_composition.author = OS.get_environment("USER")
	current_composition.bpm = bpm_slider.value if bpm_slider else 120
	has_unsaved_changes = false
	_update_composition_label()


func _update_composition_label() -> void:
	if composition_label and current_composition:
		var text = current_composition.composition_name
		if has_unsaved_changes:
			text += " *"
		composition_label.text = text


func populate_from_composition(composition: CompositionResource) -> void:
	"""Load a composition and populate the UI with its data"""
	current_composition = composition
	has_unsaved_changes = false
	
	# Update BPM
	if bpm_slider:
		bpm_slider.value = composition.bpm
	
	# Clear and repopulate layers
	clear_all_layers()
	for i in range(composition.layers.size()):
		add_layer_indicator(i)
	
	# Update sound bank if available
	# TODO: Match sound bank by ID when sound bank manager is available
	
	# Update audio bus volumes if available
	if audio_manager:
		for bus_name in composition.audio_bus_volumes:
			var volume = composition.audio_bus_volumes[bus_name]
			audio_manager.set_bus_volume(bus_name, volume)
	
	_update_composition_label()
	update_status("Loaded: " + composition.composition_name)
	
	composition_loaded.emit(composition)


func create_composition_from_current_state() -> CompositionResource:
	"""Create a composition resource from the current game state"""
	if not current_composition:
		current_composition = CompositionResource.new()
	
	# Update composition metadata
	current_composition.bpm = bpm_slider.value if bpm_slider else 120
	
	# Get current sound bank
	if sound_bank_selector:
		var bank_index = sound_bank_selector.selected
		var bank_name = sound_bank_selector.get_item_text(bank_index)
		current_composition.sound_bank_id = bank_name.to_lower()
	
	# Get audio bus volumes
	if audio_manager:
		current_composition.audio_bus_volumes.clear()
		for bus_name in ["Melody", "Bass", "Percussion", "SFX"]:
			var volume = audio_manager.get_bus_volume(bus_name)
			current_composition.audio_bus_volumes[bus_name] = volume
	
	return current_composition


func add_layer_to_composition(layer_data: CompositionResource.LayerData) -> void:
	"""Add a recorded layer to the current composition"""
	if current_composition:
		current_composition.add_layer(layer_data)
		has_unsaved_changes = true
		_update_composition_label()


func _on_save_pressed() -> void:
	# Show save dialog
	if save_dialog:
		save_name_input.text = current_composition.composition_name
		save_author_input.text = current_composition.author
		save_description_input.text = current_composition.description
		save_dialog.popup_centered(Vector2(400, 300))


func _on_load_pressed() -> void:
	# Show composition browser
	if composition_browser:
		composition_browser.visible = true
		composition_browser.refresh_list()


func _on_save_dialog_confirmed() -> void:
	if not save_name_input or not save_author_input:
		return
	
	# Update composition with dialog values
	current_composition.composition_name = save_name_input.text
	current_composition.author = save_author_input.text
	current_composition.description = save_description_input.text
	
	# Create full composition from current state
	var composition = create_composition_from_current_state()
	
	# Save the composition
	var filepath = save_system.save_composition(composition)
	if filepath:
		has_unsaved_changes = false
		_update_composition_label()


func _on_composition_saved(filepath: String, composition: CompositionResource) -> void:
	update_status("Saved: " + composition.composition_name)
	has_unsaved_changes = false
	_update_composition_label()


func _on_composition_loaded(filepath: String, composition: CompositionResource) -> void:
	populate_from_composition(composition)


func _on_save_error(error_message: String) -> void:
	update_status("Save Error: " + error_message)


func _on_load_error(error_message: String) -> void:
	update_status("Load Error: " + error_message)


func _on_browser_composition_selected(filepath: String, composition: CompositionResource) -> void:
	populate_from_composition(composition)
	composition_browser.visible = false


func _on_new_composition_requested() -> void:
	_create_new_composition()
	clear_all_layers()
	composition_browser.visible = false
	update_status("Created new composition")


func _on_import_requested() -> void:
	# TODO: Implement file dialog for importing
	update_status("Import not yet implemented")


func _on_export_requested(filepath: String) -> void:
	# TODO: Implement file dialog for exporting
	update_status("Export not yet implemented")


func _on_export_pressed() -> void:
	export_requested.emit()


func _initialize_sound_banks() -> void:
	if not sound_bank_selector:
		return
	
	# Add default sound banks - will be updated when sound bank manager is available
	sound_bank_selector.clear()
	sound_bank_selector.add_item("Electronic")
	sound_bank_selector.add_item("Ambient")
	sound_bank_selector.add_item("Orchestral")
	sound_bank_selector.add_item("Blues")
	sound_bank_selector.add_item("Minimal")
	sound_bank_selector.selected = 0


func populate_sound_banks(sound_bank_manager: Node) -> void:
	"""Populate sound bank selector from the actual sound bank manager"""
	if not sound_bank_selector or not sound_bank_manager:
		return
	
	sound_bank_selector.clear()
	
	var available_banks = sound_bank_manager.get_available_banks()
	for bank_name in available_banks:
		sound_bank_selector.add_item(bank_name)
	
	if available_banks.size() > 0:
		sound_bank_selector.selected = 0
		print("UI: Populated %d sound banks" % available_banks.size())


func set_game_mode(mode: int) -> void:
	current_mode = mode
	_update_mode_display()
	_update_ui_state()


func _update_mode_display() -> void:
	if not mode_label:
		return
	
	var mode_names = ["Live", "Recording", "Playback", "Layering"]
	if current_mode >= 0 and current_mode < mode_names.size():
		mode_label.text = "Mode: " + mode_names[current_mode]
		
		# Update mode label color
		match current_mode:
			1, 3:  # Recording, Layering
				mode_label.modulate = Color.RED
			2:  # Playback
				mode_label.modulate = Color.GREEN
			_:  # Live
				mode_label.modulate = Color.WHITE


func _update_ui_state() -> void:
	# Update button states based on mode
	match current_mode:
		0:  # LIVE
			if record_button:
				record_button.disabled = false
				record_button.text = "Record"
			if play_button:
				play_button.disabled = layers_list.item_count == 0 if layers_list else true
				play_button.text = "Play"
			if stop_button:
				stop_button.visible = false
			if clear_button:
				clear_button.disabled = layers_list.item_count == 0 if layers_list else true
			if save_button:
				save_button.disabled = layers_list.item_count == 0 if layers_list else true
			if load_button:
				load_button.disabled = false
			if export_button:
				export_button.disabled = layers_list.item_count == 0 if layers_list else true
		
		1:  # RECORDING
			if record_button:
				record_button.disabled = true
			if play_button:
				play_button.disabled = true
			if stop_button:
				stop_button.visible = true
				stop_button.text = "Stop Recording"
			if clear_button:
				clear_button.disabled = true
			if save_button:
				save_button.disabled = true
			if load_button:
				load_button.disabled = true
			if export_button:
				export_button.disabled = true
		
		2:  # PLAYBACK
			if record_button:
				record_button.disabled = false
				record_button.text = "Add Layer"
			if play_button:
				play_button.disabled = true
			if stop_button:
				stop_button.visible = true
				stop_button.text = "Stop Playback"
			if clear_button:
				clear_button.disabled = false
			if save_button:
				save_button.disabled = false
			if load_button:
				load_button.disabled = true
			if export_button:
				export_button.disabled = false
		
		3:  # LAYERING
			if record_button:
				record_button.disabled = true
			if play_button:
				play_button.disabled = true
			if stop_button:
				stop_button.visible = true
				stop_button.text = "Stop Recording"
			if clear_button:
				clear_button.disabled = true
			if save_button:
				save_button.disabled = true
			if load_button:
				load_button.disabled = true
			if export_button:
				export_button.disabled = true


func show_recording_indicator(visible: bool) -> void:
	is_recording = visible
	if recording_indicator:
		recording_indicator.visible = visible
		if visible:
			recording_indicator.text = "● REC"
			_start_recording_blink()
		else:
			_stop_recording_blink()
	
	if visible:
		has_unsaved_changes = true
		_update_composition_label()


func _start_recording_blink() -> void:
	if not recording_indicator or not is_recording:
		return
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(recording_indicator, "modulate:a", 0.3, 0.5)
	tween.tween_property(recording_indicator, "modulate:a", 1.0, 0.5)


func _stop_recording_blink() -> void:
	# Stop any running tweens on the recording indicator
	if recording_indicator:
		recording_indicator.modulate.a = 1.0


func add_layer_indicator(layer_index: int) -> void:
	if not layers_list:
		return
	
	var color = layer_colors[layer_index % layer_colors.size()]
	var layer_name = "Layer %d" % (layer_index + 1)
	
	var idx = layers_list.add_item(layer_name)
	layers_list.set_item_custom_fg_color(idx, color)
	layers_list.set_item_metadata(idx, layer_index)
	
	has_unsaved_changes = true
	_update_composition_label()
	_update_ui_state()


func remove_layer_indicator(layer_index: int) -> void:
	if not layers_list:
		return
	
	# Find and remove the item with matching metadata
	for i in range(layers_list.item_count):
		if layers_list.get_item_metadata(i) == layer_index:
			layers_list.remove_item(i)
			break
	
	has_unsaved_changes = true
	_update_composition_label()
	_update_ui_state()


func clear_all_layers() -> void:
	if layers_list:
		layers_list.clear()
	if current_composition:
		current_composition.clear_layers()
	has_unsaved_changes = true
	_update_composition_label()
	_update_ui_state()


func _on_record_pressed() -> void:
	record_pressed.emit()


func _on_play_pressed() -> void:
	play_pressed.emit()


func _on_stop_pressed() -> void:
	stop_pressed.emit()


func _on_clear_pressed() -> void:
	clear_pressed.emit()


func _on_bpm_changed(value: float) -> void:
	_update_bpm_display(value)
	bpm_changed.emit(value)
	
	# Update BeatManager
	if beat_manager:
		beat_manager.bpm = value
	
	# Update composition
	if current_composition:
		current_composition.bpm = value
		has_unsaved_changes = true
		_update_composition_label()


func _update_bpm_display(value: float) -> void:
	if bpm_value:
		bpm_value.text = str(int(value))


func _on_sound_bank_selected(index: int) -> void:
	sound_bank_changed.emit(index)
	has_unsaved_changes = true
	_update_composition_label()


func _on_layer_selected(index: int) -> void:
	if index >= 0 and index < layers_list.item_count:
		var layer_index = layers_list.get_item_metadata(index)
		layer_selected.emit(layer_index)


func _on_remove_layer_pressed() -> void:
	if not layers_list:
		return
	
	var selected = layers_list.get_selected_items()
	if selected.size() > 0:
		var index = selected[0]
		var layer_index = layers_list.get_item_metadata(index)
		layer_removed.emit(layer_index)


func _on_beat_occurred(beat_number: int, beat_time: float) -> void:
	current_beat = beat_number % 4
	_update_beat_counter()


func _on_measure_completed(measure_number: int, measure_time: float) -> void:
	current_measure = measure_number
	current_beat = 0
	_update_beat_counter()


func _update_beat_counter() -> void:
	if beat_counter_label:
		beat_counter_label.text = "Measure %d | Beat %d" % [current_measure + 1, current_beat + 1]


func update_status(text: String) -> void:
	if status_label:
		status_label.text = text


func _input(event: InputEvent) -> void:
	# Keyboard shortcuts
	if event.is_action_pressed("ui_accept"):  # Space
		if current_mode == 0 and not record_button.disabled:
			_on_record_pressed()
		elif stop_button.visible:
			_on_stop_pressed()
	
	elif event.is_action_pressed("ui_select"):  # Enter
		if current_mode == 0 and not play_button.disabled:
			_on_play_pressed()
	
	# Save/Load shortcuts
	elif event is InputEventKey and event.pressed:
		if event.ctrl_pressed:
			if event.keycode == KEY_S:  # Ctrl+S
				if not save_button.disabled:
					_on_save_pressed()
			elif event.keycode == KEY_O:  # Ctrl+O
				if not load_button.disabled:
					_on_load_pressed()
			elif event.keycode == KEY_N:  # Ctrl+N
				_on_new_composition_requested()