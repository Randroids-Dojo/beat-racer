#!/bin/bash

# run_gut_tests_ci.sh - CI-specific test runner without filtering
# Shows all output for debugging in CI environments

set -e  # Exit on error

echo "========================================  "
echo "Beat Racer GUT Test Suite (CI Mode)"
echo "========================================"

# Default values
GODOT_PATH="godot"
CONFIG_FILE=".gutconfig.json"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --godot-path)
            GODOT_PATH="$2"
            shift 2
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Check if Godot is available
if ! command -v "$GODOT_PATH" &> /dev/null; then
    echo "Error: Godot not found at '$GODOT_PATH'"
    exit 1
fi

# Run the tests
echo "Running GUT tests..."
$GODOT_PATH --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=$CONFIG_FILE -gjunit_xml_file=test_results/junit_report.xml

# Note: Exit code is automatically propagated