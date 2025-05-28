#!/bin/bash

# Run the Sound Visualization Demo
# This demo showcases all visual effects that respond to music and sound

echo "Starting Sound Visualization Demo..."
echo "=================================="
echo ""
echo "This demo shows:"
echo "- Beat-synchronized visual pulses"
echo "- Lane-specific visual effects"
echo "- Vehicle light trails based on sound"
echo "- Environment reactions to music"
echo ""
echo "Controls:"
echo "- SPACE: Start/Stop demo"
echo "- Arrow Keys: Drive vehicle"
echo "- Q/W/E: Toggle lane sounds"
echo "- 1-5: Change demo modes"
echo "- +/-: Adjust BPM"
echo "- ESC: Exit"
echo ""
echo "Demo Modes:"
echo "1. Manual - You control everything"
echo "2. Auto - Automatic lane switching"
echo "3. Music - Plays patterns"
echo "4. Chaos - Random effects"
echo "5. Zen - Calm visuals"
echo ""

# Run the demo scene
godot --path . res://scenes/test/sound_visualization_demo.tscn