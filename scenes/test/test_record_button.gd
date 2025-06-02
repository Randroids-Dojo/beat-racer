extends Node2D
## Simple test scene to verify record button functionality

@onready var record_button: Button = $RecordButton
@onready var status_label: Label = $StatusLabel

var click_count: int = 0

func _ready() -> void:
	print("Test scene ready")
	if record_button:
		print("Record button found!")
		record_button.pressed.connect(_on_record_pressed)
	else:
		print("ERROR: Record button not found!")

func _on_record_pressed() -> void:
	click_count += 1
	print("Record button clicked! Count: ", click_count)
	if status_label:
		status_label.text = "Record clicked %d times" % click_count