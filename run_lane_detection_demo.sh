#!/bin/bash

echo "Starting Lane Detection Demo..."
echo "================================="
echo "Controls:"
echo "- Arrow Keys: Drive the vehicle"
echo "- Q/E: Change lanes manually" 
echo "- Space: Toggle debug overlay"
echo "- R: Reset vehicle position"
echo "================================="

# Run the test scene
godot scenes/test/lane_detection_test.tscn