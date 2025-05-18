#!/bin/bash
# build_and_test.sh

echo "Building and testing Beat Racer..."

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_PATH="$SCRIPT_DIR"

# Check if Godot is available
if command -v godot &> /dev/null; then
    GODOT_CMD="godot"
else
    echo "Godot not found in PATH. Please install Godot or add it to your PATH."
    exit 1
fi

# Run syntax check on all GDScript files
echo "Checking GDScript syntax..."
find "$PROJECT_PATH" -name "*.gd" -not -path "*/.*" | while read -r file; do
    echo "Checking: $file"
    $GODOT_CMD --headless --path "$PROJECT_PATH" --script "$file" --check-only
done

echo ""
echo "Running audio system tests..."
$GODOT_CMD --headless --path "$PROJECT_PATH" --script res://tests/test_audio_system.gd

echo ""
echo "Running single effect test..."
$GODOT_CMD --headless --path "$PROJECT_PATH" --script res://tests/test_single_effect.gd

echo ""
echo "Tests complete!"