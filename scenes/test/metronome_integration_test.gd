extends Node2D

# Metronome Integration Test
# Tests if metronome works with BeatManager and PlaybackSync

func _ready():
	print("=== Metronome Integration Test ===")
	
	# Wait for PlaybackSync to initialize
	await get_tree().create_timer(0.5).timeout
	
	# BeatManager should be available as autoload
	print("BeatManager available: %s" % (BeatManager != null))
	print("BeatManager BPM: %d" % BeatManager.bpm)
	
	# Enable metronome
	print("\nEnabling metronome...")
	BeatManager.enable_metronome()
	
	# Start beat tracking
	print("Starting BeatManager...")
	BeatManager.start()
	
	# Run for a few seconds
	await get_tree().create_timer(5.0).timeout
	
	# Stop
	print("\nStopping...")
	BeatManager.stop()
	BeatManager.disable_metronome()
	
	print("Test complete - Check if you heard tick/tock sounds")
	print("Current beat: %d" % BeatManager.current_beat)