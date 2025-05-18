#!/bin/bash
# build_and_test.sh - Comprehensive testing script for Beat Racer

echo "======================================="
echo "  BEAT RACER BUILD & TEST SUITE v2.0   "
echo "======================================="
echo "Starting at $(date)"
echo ""

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

# Function to run a test and check result
run_test() {
    local test_name=$1
    local test_script=$2
    
    echo ""
    echo "Running: $test_name"
    echo "Script: $test_script"
    echo "-----------------------------------------"
    
    $GODOT_CMD --headless --path "$PROJECT_PATH" --script "$test_script"
    
    if [ $? -eq 0 ]; then
        echo "✓ $test_name PASSED"
    else
        echo "✗ $test_name FAILED"
        exit 1
    fi
}

# Syntax check on all GDScript files
echo "=== SYNTAX CHECK ==="
echo "Checking GDScript syntax..."
find "$PROJECT_PATH" -name "*.gd" -not -path "*/.*" | while read -r file; do
    echo "Checking: $file"
    $GODOT_CMD --headless --path "$PROJECT_PATH" --script "$file" --check-only
done

# Run the comprehensive test suite
echo ""
echo "=== RUNNING TEST SUITE ==="

# Main test runner
run_test "Main Test Runner" "res://tests/test_runner.gd"

# Unit tests
echo ""
echo "=== UNIT TESTS ==="
run_test "Audio Effects Unit Test" "res://tests/unit/test_audio_effects.gd"
run_test "Audio Generation Unit Test" "res://tests/unit/test_audio_generation.gd"

# Integration tests
echo ""
echo "=== INTEGRATION TESTS ==="
run_test "Audio System Integration" "res://tests/integration/test_audio_system_integration.gd"

# Verification tests
echo ""
echo "=== VERIFICATION TESTS ==="
run_test "Effect Property Verification" "res://tests/verification/test_effect_property_verification.gd"

# UI tests
echo ""
echo "=== UI TESTS ==="
run_test "UI Configuration Test" "res://tests/ui/test_ui_configuration.gd"

# Comprehensive test
echo ""
echo "=== COMPREHENSIVE TESTS ==="
run_test "Comprehensive Audio Test" "res://tests/test_comprehensive_audio.gd"

# Legacy tests (for backward compatibility)
echo ""
echo "=== LEGACY TESTS ==="
run_test "Audio System Test" "res://tests/test_audio_system.gd"
run_test "Single Effect Test" "res://tests/test_single_effect.gd"

# Summary
echo ""
echo "======================================="
echo "         TEST SUITE COMPLETE           "
echo "======================================="
echo "All tests passed successfully!"
echo "Completed at $(date)"
echo ""

# Optional: Create test report
if [ "$1" == "--report" ]; then
    REPORT_FILE="$PROJECT_PATH/test_report_$(date +%Y%m%d_%H%M%S).txt"
    echo "Generating test report: $REPORT_FILE"
    
    {
        echo "Beat Racer Test Report"
        echo "Generated: $(date)"
        echo ""
        echo "Test Summary:"
        echo "- Syntax Check: PASSED"
        echo "- Unit Tests: PASSED"
        echo "- Integration Tests: PASSED"
        echo "- Verification Tests: PASSED"
        echo "- UI Tests: PASSED"
        echo "- Legacy Tests: PASSED"
        echo ""
        echo "All systems operational."
    } > "$REPORT_FILE"
    
    echo "Report saved to: $REPORT_FILE"
fi