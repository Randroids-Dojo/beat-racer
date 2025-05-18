#!/bin/bash
# test_all_sequentially.sh
# Run all Beat Racer tests sequentially and capture results

echo "====================================="
echo "  BEAT RACER COMPLETE TEST SUITE"
echo "====================================="
echo "Starting at: $(date)"
echo ""

# Array of test files
tests=(
    "test_comprehensive_audio.gd"
    "test_audio_system.gd"
    "test_single_effect.gd"
    "verify_properties.gd"
    "test_chorus_properties.gd"
)

# Counter for test results
total_tests=0
passed_tests=0
failed_tests=0

# Function to run a single test
run_test() {
    local test_file=$1
    echo ""
    echo "====================================="
    echo "Running: $test_file"
    echo "====================================="
    
    # Run the test and capture exit code
    godot --headless --path . --script "res://tests/$test_file"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ $test_file PASSED"
        ((passed_tests++))
    else
        echo ""
        echo "✗ $test_file FAILED"
        ((failed_tests++))
    fi
    
    ((total_tests++))
    echo "====================================="
}

# Run each test
for test in "${tests[@]}"; do
    run_test "$test"
done

# Print summary
echo ""
echo "====================================="
echo "         TEST SUMMARY"
echo "====================================="
echo "Total tests run: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $failed_tests"
echo ""
echo "Success rate: $(( passed_tests * 100 / total_tests ))%"
echo ""
echo "Completed at: $(date)"
echo "====================================="

# Exit with appropriate code
if [ $failed_tests -eq 0 ]; then
    echo "ALL TESTS PASSED!"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi