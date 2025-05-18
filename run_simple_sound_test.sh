#!/bin/bash

# Run the Simple Sound Playback Test Scene
echo "====================================="
echo "Starting Simple Sound Playback Test"
echo "====================================="

# Check if Godot is installed
if ! command -v godot &> /dev/null; then
    echo "Error: Godot is not installed or not in PATH"
    exit 1
fi

echo "Running test scene..."
godot --path . scenes/test/simple_sound_playback_test.tscn