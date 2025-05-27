#!/bin/bash

# Run the Lane Sound Mapping Demo
# This demonstrates how vehicle lane position controls sound generation

echo "Starting Lane Sound Mapping Demo..."
echo "================================="
echo "Controls:"
echo "- Arrow Keys or WASD: Drive the vehicle"
echo "- ESC: Exit demo"
echo ""
echo "Features:"
echo "- Sound changes based on lane position"
echo "- Center lane can be configured as silent"
echo "- Smooth transitions between lane sounds"
echo "- Visual feedback for active lanes"
echo "================================="
echo ""

# Run the demo scene
godot --path . res://scenes/test/lane_sound_mapping_demo.tscn