#!/bin/bash

# Run the track test scene
echo "Starting track test scene..."
echo "==========================================="
echo "Controls:"
echo "  - Arrow Keys: Move camera"
echo "  - Mouse Wheel: Zoom in/out"
echo "  - 1,2,3: Switch test lanes"  
echo "  - Space: Start/stop movement"
echo "  - R: Reset position"
echo "  - ESC: Exit"
echo "==========================================="

godot --path . scenes/test/track_test.tscn