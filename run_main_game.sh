#!/bin/bash

# Run the main game scene with integrated systems
echo "Starting Beat Racer - Main Game..."
echo "=================================="
echo ""
echo "Controls:"
echo "  WASD/Arrow Keys - Drive vehicle"
echo "  Space - Start/stop recording"
echo "  Tab - Toggle camera mode"
echo "  ESC - Stop recording/return to live mode"
echo "  Enter - Start playback"
echo ""
echo "Game Modes:"
echo "  Live - Real-time playing with sound generation"
echo "  Recording - Record your driving path"
echo "  Playback - Play recorded layers"
echo "  Layering - Record new layers over existing ones"
echo ""

godot --path . res://scenes/main_game.tscn