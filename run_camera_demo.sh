#!/bin/bash

# Camera System Demo Runner
# Demonstrates dynamic camera following with zoom and screen shake

echo "========================================"
echo "Beat Racer - Camera System Demo"
echo "========================================"
echo
echo "This demo showcases the camera system features:"
echo "• Smooth vehicle following with configurable smoothing"
echo "• Speed-based zoom that adjusts based on vehicle velocity"
echo "• Overview mode for seeing the entire track"
echo "• Smooth transitions between different camera targets"
echo "• Screen shake effects with multiple types and intensities"
echo "• Real-time camera parameter adjustment"
echo
echo "Controls:"
echo "  Movement:"
echo "    W/S - Accelerate/Brake"
echo "    A/D - Steer left/right"
echo "    SPACE - Handbrake"
echo
echo "  Camera:"
echo "    V - Switch between vehicles"
echo "    O - Overview mode (see entire track)"
echo "    F - Follow mode (follow current vehicle)"
echo "    R - Reset vehicle positions"
echo
echo "  Screen Shake:"
echo "    1 - Small impact shake"
echo "    2 - Continuous rumble"
echo "    3 - Explosion shake"
echo "    4 - Directional shake"
echo
echo "  ESC - Quit demo"
echo
echo "Camera settings can be adjusted in real-time using the sliders."
echo "Watch the info panel for camera mode, zoom level, and shake intensity."
echo
echo "Press any key to start the demo..."
read -n 1 -s

echo "Starting camera demo..."

# Run the demo
godot --path . res://scenes/test/camera_demo.tscn

echo "Camera demo finished."