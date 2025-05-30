#!/bin/bash

# Audio Mixer Demo - Story 014
# This script runs the audio mixing controls demonstration

echo "=== Beat Racer - Audio Mixer Demo ==="
echo "Starting audio mixer control demonstration..."
echo ""
echo "Features to test:"
echo "• Volume sliders for each audio bus"
echo "• Mute/Solo buttons"
echo "• Effect parameter controls"
echo "• Audio preset save/load system"
echo "• Real-time audio mixing"
echo ""
echo "Use ESC to exit the demo"
echo ""

# Run the demo scene
godot --path . res://scenes/test/audio_mixer_demo.tscn

echo "Audio mixer demo completed."