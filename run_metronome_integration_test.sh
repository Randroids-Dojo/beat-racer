#!/bin/bash

echo "Running Metronome Integration Test..."
echo "This will test if metronome sounds play when integrated with BeatManager"
echo "You should hear tick/tock sounds for 5 seconds"
echo ""

godot --path . res://scenes/test/metronome_integration_test.tscn