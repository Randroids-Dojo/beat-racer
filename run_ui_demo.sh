#!/bin/bash

# Run the UI elements demo scene
echo "Starting UI Elements Demo..."
echo "============================"
echo "This demo showcases all UI elements from Story 012:"
echo ""
echo "UI Components:"
echo "  - Recording/Playback Status Indicator"
echo "  - Beat/Measure Counter"
echo "  - BPM Control with Tap Tempo"
echo "  - Vehicle Selection with Preview"
echo ""
echo "Controls:"
echo "  Arrow Keys: Drive the vehicle"
echo "  SPACE: Start/Stop recording"
echo "  P: Play/Pause playback"
echo "  TAB: Toggle UI visibility"
echo "  ESC: Stop all"
echo ""
echo "Try the tap tempo feature by clicking 'Tap Tempo' button"
echo "in rhythm with your desired BPM!"
echo "============================"
echo ""

# Run the demo scene
godot --path . res://scenes/test/ui_demo.tscn