extends Control
## Enhanced UI panel for the main game scene
##
## This panel integrates all UI elements from previous stories and adds
## game mode management, layer display, and unified controls for the
## complete Beat Racer experience.

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

# UI Component References
@onready var mode_label: Label = $TopBar/ModeLabel
@onready var bpm_slider: HSlider = $TopBar/BPMControl/BPMSlider
@onready var bpm_value: Label = $TopBar/BPMControl/BPMValue
@onready var record_button: Button = $TopBar/RecordButton
@onready var play_button: Button = $TopBar/PlayButton
@onready var stop_button: Button = $TopBar/StopButton
@onready var clear_button: Button = $TopBar/ClearButton

@onready var sound_bank_selector: OptionButton = $LeftPanel/SoundBankSection/SoundBankSelector
@onready var layers_list: ItemList = $LeftPanel/LayersSection/LayersList
@onready var layer_remove_button: Button = $LeftPanel/LayersSection/RemoveLayerButton

@onready var status_label: Label = $BottomBar/StatusLabel
@onready var recording_indicator: Label = $BottomBar/RecordingIndicator
@onready var beat_counter_label: Label = $BottomBar/BeatCounter

@onready var beat_viz_panel: PanelContainer = $RightPanel/BeatVisualizationPanel
@onready var audio_mixer_panel: Panel = $RightPanel/AudioMixerPanel

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

# References
@onready var beat_manager: Node = get_node("/root/BeatManager")
@onready var audio_manager: Node = get_node("/root/AudioManager")


func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_initialize_sound_banks()
	_update_ui_state()


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


func _connect_signals() -> void:
	print("UI Panel: Connecting signals...")
	# Button signals
	print("record_button reference: ", record_button)
	if record_button:
		print("Connecting record button signal")
		record_button.pressed.connect(_on_record_pressed)
	else:
		print("ERROR: record_button is null!")
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if stop_button:
		stop_button.pressed.connect(_on_stop_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
	
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


func show_recording_indicator(visible: bool) -> void:
	is_recording = visible
	if recording_indicator:
		recording_indicator.visible = visible
		if visible:
			recording_indicator.text = "● REC"
			_start_recording_blink()
		else:
			_stop_recording_blink()


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
	
	_update_ui_state()


func remove_layer_indicator(layer_index: int) -> void:
	if not layers_list:
		return
	
	# Find and remove the item with matching metadata
	for i in range(layers_list.item_count):
		if layers_list.get_item_metadata(i) == layer_index:
			layers_list.remove_item(i)
			break
	
	_update_ui_state()


func clear_all_layers() -> void:
	if layers_list:
		layers_list.clear()
	_update_ui_state()


func _on_record_pressed() -> void:
	print("UI Panel: Record button clicked, emitting signal")
	
	# Immediate visual feedback
	if status_label:
		status_label.text = "Record button pressed - processing..."
		status_label.modulate = Color.YELLOW
	
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


func _update_bpm_display(value: float) -> void:
	if bpm_value:
		bpm_value.text = str(int(value))


func _on_sound_bank_selected(index: int) -> void:
	sound_bank_changed.emit(index)


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
		status_label.modulate = Color.WHITE  # Reset color


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
