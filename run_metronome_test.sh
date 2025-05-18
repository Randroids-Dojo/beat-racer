#!/bin/bash

# Run the metronome test scene
echo "Running Metronome Test Scene..."
echo "Controls:"
echo "  - Click 'Play Tick' and 'Play Tock' to test individual sounds"
echo "  - Click 'Enable Metronome' to start the metronome with BeatManager"
echo "  - Adjust BPM and Volume sliders"
echo "  - Press ESC to exit"
echo ""

godot --path . res://scenes/test/metronome_test.tscn