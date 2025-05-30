#!/bin/bash

# Sound Bank Demo Runner
# Story 017: Multiple Sound Banks

echo "Starting Sound Bank Demo..."
echo "This demonstrates the new multiple sound bank system with:"
echo "  • 5 default sound banks (Electronic, Ambient, Orchestral, Blues, Minimal)"
echo "  • Real-time bank switching during gameplay"  
echo "  • Lane-based sound triggering"
echo "  • Sound bank management UI"
echo ""
echo "Controls:"
echo "  • A/D - Switch between banks"
echo "  • Q/W/E - Trigger Left/Center/Right lanes"
echo "  • 1-7 - Select scale degrees"
echo "  • Space - Toggle auto-play"
echo "  • PageUp/PageDown - Bank switching (in-game style)"
echo ""

# Run the demo scene
godot --path . res://scenes/test/sound_bank_demo.tscn