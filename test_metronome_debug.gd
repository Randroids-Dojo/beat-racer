extends Node

# Debug script to test metronome functionality

func _ready():
	print("=== METRONOME DEBUG TEST ===")
	
	# Get BeatManager reference
	var beat_manager = get_node("/root/BeatManager")
	if not beat_manager:
		print("ERROR: BeatManager not found!")
		return
	
	# Create PlaybackSync
	var PlaybackSyncClass = preload("res://scripts/components/sound/playback_sync.gd")
	var playback_sync = PlaybackSyncClass.new()
	add_child(playback_sync)
	
	print("Created PlaybackSync")
	
	# Wait for initialization
	await get_tree().create_timer(0.1).timeout
	
	# Test metronome
	print("Enabling metronome...")
	beat_manager.enable_metronome()
	
	print("Starting BeatManager...")
	beat_manager.bpm = 120
	beat_manager.start()
	
	# Let it run for a few beats
	await get_tree().create_timer(3.0).timeout
	
	print("Stopping BeatManager...")
	beat_manager.stop()
	beat_manager.disable_metronome()
	
	print("=== TEST COMPLETE ===")
	get_tree().quit()