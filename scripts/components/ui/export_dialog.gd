extends AcceptDialog
class_name ExportDialog
## Dialog for exporting audio recordings with options
##
## This dialog provides a user interface for exporting compositions
## as audio files with various options and metadata.

signal export_requested(options: Dictionary)

# UI Controls
@onready var filename_input: LineEdit = $VBox/FilenameContainer/FilenameInput
@onready var format_option: OptionButton = $VBox/FormatContainer/FormatOption
@onready var quality_option: OptionButton = $VBox/QualityContainer/QualityOption
@onready var include_metadata_check: CheckBox = $VBox/MetadataCheck
@onready var open_folder_check: CheckBox = $VBox/OpenFolderCheck
@onready var duration_label: Label = $VBox/InfoContainer/DurationLabel
@onready var size_estimate_label: Label = $VBox/InfoContainer/SizeLabel

# Current recording info
var recording_duration: float = 0.0
var composition_name: String = "Untitled"


func _ready() -> void:
	# Setup dialog
	title = "Export Audio Recording"
	set_ok_button_text("Export")
	set_cancel_button_text("Cancel")
	
	# Create UI if nodes don't exist
	if not $VBox:
		_create_ui()
	
	# Connect signals
	get_ok_button().pressed.connect(_on_export_pressed)
	
	# Setup format options
	if format_option:
		format_option.clear()
		format_option.add_item("WAV (Lossless)", 0)
		format_option.add_item("MP3 (Coming Soon)", 1)
		format_option.add_item("OGG (Coming Soon)", 2)
		format_option.set_item_disabled(1, true)
		format_option.set_item_disabled(2, true)
		format_option.selected = 0
	
	# Setup quality options
	if quality_option:
		quality_option.clear()
		quality_option.add_item("High (44.1 kHz, 16-bit)", 0)
		quality_option.add_item("Medium (22.05 kHz, 16-bit)", 1)
		quality_option.add_item("Low (11.025 kHz, 8-bit)", 2)
		quality_option.selected = 0
		quality_option.visible = false  # Hide for WAV format
	
	# Set defaults
	if include_metadata_check:
		include_metadata_check.button_pressed = true
	if open_folder_check:
		open_folder_check.button_pressed = true


func _create_ui() -> void:
	# Create main container
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	
	# Filename section
	var filename_container = HBoxContainer.new()
	filename_container.name = "FilenameContainer"
	vbox.add_child(filename_container)
	
	var filename_label = Label.new()
	filename_label.text = "Filename:"
	filename_label.custom_minimum_size.x = 100
	filename_container.add_child(filename_label)
	
	filename_input = LineEdit.new()
	filename_input.name = "FilenameInput"
	filename_input.placeholder_text = "Enter filename..."
	filename_input.custom_minimum_size.x = 300
	filename_container.add_child(filename_input)
	
	# Format section
	var format_container = HBoxContainer.new()
	format_container.name = "FormatContainer"
	vbox.add_child(format_container)
	
	var format_label = Label.new()
	format_label.text = "Format:"
	format_label.custom_minimum_size.x = 100
	format_container.add_child(format_label)
	
	format_option = OptionButton.new()
	format_option.name = "FormatOption"
	format_option.custom_minimum_size.x = 200
	format_container.add_child(format_option)
	
	# Quality section
	var quality_container = HBoxContainer.new()
	quality_container.name = "QualityContainer"
	vbox.add_child(quality_container)
	
	var quality_label = Label.new()
	quality_label.text = "Quality:"
	quality_label.custom_minimum_size.x = 100
	quality_container.add_child(quality_label)
	
	quality_option = OptionButton.new()
	quality_option.name = "QualityOption"
	quality_option.custom_minimum_size.x = 200
	quality_container.add_child(quality_option)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Options
	include_metadata_check = CheckBox.new()
	include_metadata_check.name = "MetadataCheck"
	include_metadata_check.text = "Include composition metadata (JSON)"
	vbox.add_child(include_metadata_check)
	
	open_folder_check = CheckBox.new()
	open_folder_check.name = "OpenFolderCheck"
	open_folder_check.text = "Open folder after export"
	vbox.add_child(open_folder_check)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Info section
	var info_container = VBoxContainer.new()
	info_container.name = "InfoContainer"
	vbox.add_child(info_container)
	
	duration_label = Label.new()
	duration_label.name = "DurationLabel"
	duration_label.text = "Duration: 0:00"
	info_container.add_child(duration_label)
	
	size_estimate_label = Label.new()
	size_estimate_label.name = "SizeLabel"
	size_estimate_label.text = "Estimated size: 0 MB"
	info_container.add_child(size_estimate_label)


func setup(composition_name_param: String, duration: float) -> void:
	composition_name = composition_name_param
	recording_duration = duration
	
	# Set default filename
	if filename_input:
		var safe_name = composition_name.to_snake_case().strip_edges()
		if safe_name.is_empty():
			safe_name = "untitled"
		# Add timestamp
		var datetime = Time.get_datetime_dict_from_system()
		var timestamp = "%04d%02d%02d_%02d%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute
		]
		filename_input.text = "%s_%s" % [safe_name, timestamp]
	
	# Update info labels
	_update_info_labels()


func _update_info_labels() -> void:
	# Update duration
	if duration_label:
		var minutes = int(recording_duration) / 60
		var seconds = int(recording_duration) % 60
		duration_label.text = "Duration: %d:%02d" % [minutes, seconds]
	
	# Update size estimate
	if size_estimate_label:
		var size_mb = _estimate_file_size()
		size_estimate_label.text = "Estimated size: %.1f MB" % size_mb


func _estimate_file_size() -> float:
	# WAV file size calculation:
	# size = sample_rate * bit_depth/8 * channels * duration
	var sample_rate = 44100  # Hz
	var bit_depth = 16  # bits
	var channels = 2  # stereo
	
	match quality_option.selected if quality_option else 0:
		1:  # Medium
			sample_rate = 22050
		2:  # Low
			sample_rate = 11025
			bit_depth = 8
	
	var bytes_per_second = sample_rate * (bit_depth / 8) * channels
	var total_bytes = bytes_per_second * recording_duration
	var size_mb = total_bytes / (1024.0 * 1024.0)
	
	return size_mb


func _on_export_pressed() -> void:
	var filename = filename_input.text.strip_edges()
	
	if filename.is_empty():
		filename = "untitled_export"
	
	# Remove any file extension the user might have added
	if filename.ends_with(".wav") or filename.ends_with(".mp3") or filename.ends_with(".ogg"):
		filename = filename.get_basename()
	
	# Sanitize filename
	filename = filename.replace(" ", "_")
	filename = filename.replace("/", "_")
	filename = filename.replace("\\", "_")
	
	# Build export options
	var options = {
		"filename": filename,
		"format": "wav",  # Only WAV supported for now
		"quality": quality_option.selected if quality_option else 0,
		"include_metadata": include_metadata_check.button_pressed if include_metadata_check else true,
		"open_folder": open_folder_check.button_pressed if open_folder_check else false
	}
	
	export_requested.emit(options)
	hide()


func _on_format_changed(index: int) -> void:
	# Show/hide quality options based on format
	if quality_option:
		quality_option.visible = index != 0  # Hide for WAV
	
	# Update size estimate
	_update_info_labels()