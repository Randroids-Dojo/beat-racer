extends GutTest
## Unit tests for the audio export system
##
## Tests the GameAudioRecorder and CompositionRecorder classes
## to ensure audio recording and export functionality works correctly.

var audio_recorder: GameAudioRecorder
var composition_recorder: CompositionRecorder
var test_audio_file_path: String = "user://test_recording.wav"


func before_each() -> void:
	# Clean up any existing test files
	var dir = DirAccess.open("user://")
	if dir.file_exists("test_recording.wav"):
		dir.remove("test_recording.wav")
	if dir.file_exists("test_recording_metadata.json"):
		dir.remove("test_recording_metadata.json")
	
	# Create audio recorder
	audio_recorder = GameAudioRecorder.new()
	add_child_autofree(audio_recorder)
	
	# Create composition recorder
	composition_recorder = CompositionRecorder.new()
	add_child_autofree(composition_recorder)


func after_each() -> void:
	# Clean up test files
	var dir = DirAccess.open("user://")
	if dir.file_exists("test_recording.wav"):
		dir.remove("test_recording.wav")
	if dir.file_exists("test_recording_metadata.json"):
		dir.remove("test_recording_metadata.json")


func test_audio_recorder_setup() -> void:
	# Test that audio recorder sets up recording bus correctly
	assert_not_null(audio_recorder, "Audio recorder should be created")
	
	# Check if Record bus exists
	var record_bus_idx = AudioServer.get_bus_index("Record")
	assert_ne(record_bus_idx, -1, "Record bus should exist")
	
	# Check if record effect is added
	var has_record_effect = false
	for i in range(AudioServer.get_bus_effect_count(record_bus_idx)):
		if AudioServer.get_bus_effect(record_bus_idx, i) is AudioEffectRecord:
			has_record_effect = true
			break
	assert_true(has_record_effect, "Record bus should have AudioEffectRecord")


func test_start_stop_recording() -> void:
	# Test starting and stopping recording
	assert_false(audio_recorder.is_recording, "Should not be recording initially")
	
	audio_recorder.start_recording()
	assert_true(audio_recorder.is_recording, "Should be recording after start")
	
	# Wait a bit to generate some recording
	await wait_seconds(0.1)
	
	var recording = audio_recorder.stop_recording()
	assert_false(audio_recorder.is_recording, "Should not be recording after stop")
	assert_not_null(recording, "Should return a recording")


func test_save_recording() -> void:
	# Test saving a recording
	audio_recorder.start_recording()
	await wait_seconds(0.1)
	var recording = audio_recorder.stop_recording()
	
	assert_true(audio_recorder.has_recording(), "Should have a recording")
	
	var saved_path = audio_recorder.save_recording("test_recording.wav")
	assert_eq(saved_path, "user://recordings/test_recording.wav", "Should return correct path")
	
	# Check if file exists
	var dir = DirAccess.open("user://recordings/")
	assert_true(dir.file_exists("test_recording.wav"), "Recording file should exist")


func test_recording_duration() -> void:
	# Test recording duration tracking
	audio_recorder.start_recording()
	
	await wait_seconds(0.5)
	
	var duration = audio_recorder.get_recording_duration()
	assert_almost_eq(duration, 0.5, 0.1, "Duration should be approximately 0.5 seconds")
	
	audio_recorder.stop_recording()


func test_max_recording_duration() -> void:
	# Test that recording stops at max duration
	audio_recorder.max_recording_duration = 0.2  # Set very short max duration
	
	audio_recorder.start_recording()
	assert_true(audio_recorder.is_recording, "Should be recording")
	
	# Wait for max duration to pass
	await wait_seconds(0.3)
	
	assert_false(audio_recorder.is_recording, "Recording should stop at max duration")


func test_composition_recorder_metadata() -> void:
	# Test composition recorder metadata capture
	composition_recorder.start_composition_recording("Test Track", [])
	
	await wait_seconds(0.1)
	
	var result = composition_recorder.stop_composition_recording()
	
	assert_has(result, "audio", "Result should have audio")
	assert_has(result, "metadata", "Result should have metadata")
	
	var metadata = result.metadata
	assert_eq(metadata.track_name, "Test Track", "Track name should match")
	assert_has(metadata, "bpm", "Metadata should have BPM")
	assert_has(metadata, "duration", "Metadata should have duration")
	assert_has(metadata, "start_time", "Metadata should have start time")
	assert_has(metadata, "end_time", "Metadata should have end time")


func test_composition_save_with_metadata() -> void:
	# Test saving composition with metadata
	composition_recorder.start_composition_recording("Test Composition", [])
	await wait_seconds(0.1)
	composition_recorder.stop_composition_recording()
	
	var result = composition_recorder.save_composition("test_composition")
	
	assert_has(result, "audio_path", "Result should have audio path")
	assert_has(result, "metadata_path", "Result should have metadata path")
	
	# Check if files exist
	var dir = DirAccess.open("user://recordings/")
	assert_true(dir.file_exists("test_composition.wav"), "Audio file should exist")
	assert_true(dir.file_exists("test_composition_metadata.json"), "Metadata file should exist")
	
	# Verify metadata content
	var metadata_file = FileAccess.open(result.metadata_path, FileAccess.READ)
	if metadata_file:
		var json_text = metadata_file.get_as_text()
		metadata_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		assert_eq(parse_result, OK, "Metadata should be valid JSON")
		
		var metadata = json.data
		assert_eq(metadata.track_name, "Test Composition", "Saved metadata should have correct track name")


func test_export_with_options() -> void:
	# Test export with custom options
	composition_recorder.start_composition_recording("Export Test", [])
	await wait_seconds(0.1)
	composition_recorder.stop_composition_recording()
	
	var options = {
		"filename": "custom_export",
		"include_metadata": true,
		"format": "wav"
	}
	
	var result = composition_recorder.export_with_options(options)
	
	assert_has(result, "audio_path", "Export should return audio path")
	assert_true(result.audio_path.ends_with("custom_export.wav"), "Export should use custom filename")
	
	# Check if metadata was included
	assert_has(result, "metadata_path", "Export should include metadata when requested")


func test_recording_signals() -> void:
	# Test that signals are emitted correctly
	var recording_started = false
	var recording_stopped = false
	var recording_saved = false
	
	audio_recorder.recording_started.connect(func(): recording_started = true)
	audio_recorder.recording_stopped.connect(func(rec): recording_stopped = true)
	audio_recorder.recording_saved.connect(func(path): recording_saved = true)
	
	audio_recorder.start_recording()
	assert_true(recording_started, "recording_started signal should be emitted")
	
	await wait_seconds(0.1)
	
	audio_recorder.stop_recording()
	assert_true(recording_stopped, "recording_stopped signal should be emitted")
	
	audio_recorder.save_recording("signal_test.wav")
	assert_true(recording_saved, "recording_saved signal should be emitted")


func test_audio_bus_routing() -> void:
	# Test that audio buses are correctly routed for recording
	var buses_to_check = ["Melody", "Bass", "Percussion", "SFX"]
	var record_bus_idx = AudioServer.get_bus_index("Record")
	
	for bus_name in buses_to_check:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx != -1:
			var send_bus = AudioServer.get_bus_send(bus_idx)
			assert_eq(send_bus, "Record", "Bus %s should send to Record bus" % bus_name)