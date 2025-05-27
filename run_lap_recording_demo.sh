#!/bin/bash

# Run the Lap Recording Demo
# This demonstrates the lap recording system

echo "Starting Lap Recording Demo..."
echo "==============================="
echo "Controls:"
echo "- Arrow Keys or WASD: Drive the vehicle"
echo "- SPACE: Start/Stop recording"
echo "- R: Reset vehicle position"
echo "- ESC: Exit demo"
echo ""
echo "Features:"
echo "- Records vehicle position and lane data"
echo "- Samples position at configurable rate"
echo "- Detects lap completion automatically"
echo "- Stores multiple lap recordings"
echo "- Visual recording indicator"
echo "==============================="
echo ""

# Run the demo scene
godot --path . res://scenes/test/lap_recording_demo.tscn