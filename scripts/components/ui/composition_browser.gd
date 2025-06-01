class_name CompositionBrowser
extends PanelContainer

signal composition_selected(filepath: String, composition: CompositionResource)
signal composition_deleted(filepath: String)
signal new_composition_requested()
signal import_requested()
signal export_requested(filepath: String)

@onready var item_list: ItemList = $VBoxContainer/ScrollContainer/ItemList
@onready var search_line_edit: LineEdit = $VBoxContainer/SearchContainer/SearchLineEdit
@onready var sort_option_button: OptionButton = $VBoxContainer/SearchContainer/SortOptionButton
@onready var info_panel: PanelContainer = $VBoxContainer/InfoPanel
@onready var info_label: RichTextLabel = $VBoxContainer/InfoPanel/MarginContainer/InfoLabel
@onready var button_container: HBoxContainer = $VBoxContainer/ButtonContainer
@onready var new_button: Button = $VBoxContainer/ButtonContainer/NewButton
@onready var load_button: Button = $VBoxContainer/ButtonContainer/LoadButton
@onready var delete_button: Button = $VBoxContainer/ButtonContainer/DeleteButton
@onready var import_button: Button = $VBoxContainer/ButtonContainer/ImportButton
@onready var export_button: Button = $VBoxContainer/ButtonContainer/ExportButton
@onready var refresh_button: Button = $VBoxContainer/SearchContainer/RefreshButton

var save_system: CompositionSaveSystem
var compositions: Array[Dictionary] = []
var filtered_compositions: Array[Dictionary] = []
var selected_index: int = -1

enum SortMode {
	DATE_NEWEST,
	DATE_OLDEST,
	NAME_AZ,
	NAME_ZA,
	DURATION,
	LAYERS
}

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	
	save_system = CompositionSaveSystem.new()
	add_child(save_system)
	
	refresh_list()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(600, 400)
	
	sort_option_button.add_item("Newest First", SortMode.DATE_NEWEST)
	sort_option_button.add_item("Oldest First", SortMode.DATE_OLDEST)
	sort_option_button.add_item("Name (A-Z)", SortMode.NAME_AZ)
	sort_option_button.add_item("Name (Z-A)", SortMode.NAME_ZA)
	sort_option_button.add_item("Duration", SortMode.DURATION)
	sort_option_button.add_item("Layers", SortMode.LAYERS)
	sort_option_button.selected = 0
	
	item_list.allow_rmb_select = true
	
	load_button.disabled = true
	delete_button.disabled = true
	export_button.disabled = true
	
	info_panel.visible = false

func _connect_signals() -> void:
	new_button.pressed.connect(_on_new_pressed)
	load_button.pressed.connect(_on_load_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	import_button.pressed.connect(_on_import_pressed)
	export_button.pressed.connect(_on_export_pressed)
	refresh_button.pressed.connect(refresh_list)
	
	item_list.item_selected.connect(_on_item_selected)
	item_list.item_activated.connect(_on_item_activated)
	item_list.gui_input.connect(_on_item_list_input)
	
	search_line_edit.text_changed.connect(_on_search_text_changed)
	sort_option_button.item_selected.connect(_on_sort_mode_changed)

func refresh_list() -> void:
	compositions = save_system.list_saved_compositions()
	_apply_filters()
	_update_list_display()

func _apply_filters() -> void:
	filtered_compositions.clear()
	
	var search_text := search_line_edit.text.to_lower()
	
	for comp in compositions:
		if search_text.is_empty() or \
		   comp.name.to_lower().contains(search_text) or \
		   comp.author.to_lower().contains(search_text):
			filtered_compositions.append(comp)
	
	_sort_compositions()

func _sort_compositions() -> void:
	var sort_mode := sort_option_button.get_selected_id()
	
	match sort_mode:
		SortMode.DATE_NEWEST:
			filtered_compositions.sort_custom(func(a, b): return a.modification_date > b.modification_date)
		SortMode.DATE_OLDEST:
			filtered_compositions.sort_custom(func(a, b): return a.modification_date < b.modification_date)
		SortMode.NAME_AZ:
			filtered_compositions.sort_custom(func(a, b): return a.name < b.name)
		SortMode.NAME_ZA:
			filtered_compositions.sort_custom(func(a, b): return a.name > b.name)
		SortMode.DURATION:
			filtered_compositions.sort_custom(func(a, b): return a.duration > b.duration)
		SortMode.LAYERS:
			filtered_compositions.sort_custom(func(a, b): return a.layers > b.layers)

func _update_list_display() -> void:
	item_list.clear()
	selected_index = -1
	
	for i in range(filtered_compositions.size()):
		var comp := filtered_compositions[i]
		var item_text := comp.name
		
		if comp.is_autosave:
			item_text = "[AUTO] " + item_text
		
		item_text += "\n"
		item_text += "  %s | %d layers | BPM: %.0f | %s" % [
			comp.duration,
			comp.layers,
			comp.bpm,
			_format_date(comp.modification_date)
		]
		
		item_list.add_item(item_text)
		item_list.set_item_metadata(i, comp)
		
		if comp.is_autosave:
			item_list.set_item_custom_fg_color(i, Color(0.7, 0.7, 0.7))
	
	_update_button_states()

func _format_date(date_str: String) -> String:
	if date_str.is_empty():
		return "Unknown"
	
	var parts := date_str.split("T")
	if parts.size() >= 1:
		return parts[0]
	
	return date_str

func _update_button_states() -> void:
	var has_selection := selected_index >= 0
	load_button.disabled = not has_selection
	delete_button.disabled = not has_selection
	export_button.disabled = not has_selection

func _show_composition_info(comp: Dictionary) -> void:
	info_panel.visible = true
	
	var info_text := "[b]%s[/b]\n" % comp.name
	info_text += "by %s\n\n" % comp.author
	info_text += "[b]Details:[/b]\n"
	info_text += "• Duration: %s\n" % comp.duration
	info_text += "• Layers: %d\n" % comp.layers
	info_text += "• BPM: %.0f\n" % comp.bpm
	info_text += "• Created: %s\n" % _format_date(comp.creation_date)
	info_text += "• Modified: %s\n" % _format_date(comp.modification_date)
	info_text += "• File size: %s\n" % _format_file_size(comp.file_size)
	
	if comp.is_autosave:
		info_text += "\n[color=yellow]This is an autosave[/color]"
	
	info_label.text = info_text

func _format_file_size(size: int) -> String:
	if size < 1024:
		return "%d B" % size
	elif size < 1024 * 1024:
		return "%.1f KB" % (size / 1024.0)
	else:
		return "%.1f MB" % (size / (1024.0 * 1024.0))

func _on_item_selected(index: int) -> void:
	selected_index = index
	_update_button_states()
	
	if index >= 0 and index < filtered_compositions.size():
		_show_composition_info(filtered_compositions[index])

func _on_item_activated(index: int) -> void:
	_on_load_pressed()

func _on_item_list_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			var index := item_list.get_item_at_position(mb.position)
			if index >= 0:
				selected_index = index
				item_list.select(index)
				_update_button_states()
				_show_context_menu(mb.global_position)

func _show_context_menu(position: Vector2) -> void:
	var menu := PopupMenu.new()
	menu.add_item("Load", 0)
	menu.add_item("Export", 1)
	menu.add_separator()
	menu.add_item("Delete", 2)
	
	menu.id_pressed.connect(_on_context_menu_id_pressed)
	add_child(menu)
	menu.popup(Rect2(position, Vector2.ZERO))
	menu.popup_hide.connect(menu.queue_free)

func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		0: _on_load_pressed()
		1: _on_export_pressed()
		2: _on_delete_pressed()

func _on_new_pressed() -> void:
	new_composition_requested.emit()

func _on_load_pressed() -> void:
	if selected_index < 0 or selected_index >= filtered_compositions.size():
		return
	
	var comp_info := filtered_compositions[selected_index]
	var composition := save_system.load_composition(comp_info.filepath)
	
	if composition:
		composition_selected.emit(comp_info.filepath, composition)

func _on_delete_pressed() -> void:
	if selected_index < 0 or selected_index >= filtered_compositions.size():
		return
	
	var comp_info := filtered_compositions[selected_index]
	
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure you want to delete '%s'?\nThis action cannot be undone." % comp_info.name
	dialog.confirmed.connect(_confirm_delete.bind(comp_info.filepath))
	add_child(dialog)
	dialog.popup_centered()
	dialog.popup_hide.connect(dialog.queue_free)

func _confirm_delete(filepath: String) -> void:
	if save_system.delete_composition(filepath):
		composition_deleted.emit(filepath)
		refresh_list()

func _on_import_pressed() -> void:
	import_requested.emit()

func _on_export_pressed() -> void:
	if selected_index < 0 or selected_index >= filtered_compositions.size():
		return
	
	var comp_info := filtered_compositions[selected_index]
	export_requested.emit(comp_info.filepath)

func _on_search_text_changed(text: String) -> void:
	_apply_filters()
	_update_list_display()

func _on_sort_mode_changed(index: int) -> void:
	_apply_filters()
	_update_list_display()