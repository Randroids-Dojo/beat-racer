#!/bin/bash

# Run the path playback demo scene
echo "Starting Path Playback Demo..."
echo "================================"
echo "This demo shows lap recording and automatic playback."
echo ""
echo "Controls:"
echo "  Arrow Keys: Drive the vehicle"
echo "  SPACE: Start/Stop recording"
echo "  P: Play/Pause playback"
echo "  S: Stop playback"
echo "  L: Toggle loop mode"
echo "  1-3: Adjust playback speed (0.5x, 1x, 2x)"
echo ""
echo "Record a lap by driving around the track, then watch"
echo "the ghost vehicle replay your path!"
echo "================================"
echo ""

# Run the demo scene
godot --path . res://scenes/test/path_playback_demo.tscn