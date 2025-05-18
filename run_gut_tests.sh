#!/bin/bash

# run_gut_tests.sh - CI/CD script for running GUT tests
# For Beat Racer Godot project

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Beat Racer GUT Test Suite${NC}"
echo -e "${GREEN}========================================${NC}"

# Default values
GODOT_PATH="godot"
CONFIG_FILE=".gutconfig.json"
EXIT_CODE=0
GENERATE_REPORT=false
VERBOSE=false

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
        --report)
            GENERATE_REPORT=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --godot-path PATH    Path to Godot executable (default: godot)"
            echo "  --config FILE        GUT config file (default: .gutconfig.json)"
            echo "  --report            Generate JUnit XML report"
            echo "  --verbose           Show detailed test output"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Check if Godot is available
echo -e "${YELLOW}Checking Godot installation...${NC}"
if ! command -v "$GODOT_PATH" &> /dev/null; then
    echo -e "${RED}Error: Godot not found at '$GODOT_PATH'${NC}"
    echo "Please install Godot or specify the path with --godot-path"
    exit 1
fi

# Get Godot version
GODOT_VERSION=$("$GODOT_PATH" --version | head -n 1)
echo -e "${GREEN}Found Godot: $GODOT_VERSION${NC}"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file '$CONFIG_FILE' not found${NC}"
    exit 1
fi

# Create test results directory
mkdir -p test_results

# Run the tests
echo -e "\n${YELLOW}Running GUT tests...${NC}"

# Build the command
CMD="$GODOT_PATH --headless --path . -s addons/gut/gut_cmdln.gd"

# Add verbose flag if requested
if [ "$VERBOSE" = true ]; then
    CMD="$CMD -gverbose"
fi

# Add config file
CMD="$CMD -gconfig=$CONFIG_FILE"

# Add JUnit output if requested
if [ "$GENERATE_REPORT" = true ]; then
    CMD="$CMD -gjunit_xml_file=test_results/junit_report.xml"
fi

# Execute the tests
echo -e "${YELLOW}Executing: $CMD${NC}\n"

# Run tests and capture output
OUTPUT=$($CMD 2>&1)
EXIT_CODE=$?

# Filter out only truly unavoidable warnings
FILTERED_OUTPUT=$(echo "$OUTPUT" | grep -v "AVCaptureDeviceTypeExternal" | \
    grep -v "ObjectDB instances leaked at exit" | \
    grep -v "resources still in use at exit" | \
    grep -v "RID allocations of type" | \
    grep -v "RIDs of type \"CanvasItem\" were leaked")

# Display filtered output
echo "$FILTERED_OUTPUT"

# Check exit code
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
else
    echo -e "\n${RED}Tests failed with exit code: $EXIT_CODE${NC}"
fi

# Process results if report was generated
if [ "$GENERATE_REPORT" = true ]; then
    REPORT_FILES=test_results/junit_report*.xml
    for f in $REPORT_FILES; do
        if [ -f "$f" ]; then
            echo -e "\n${YELLOW}Test report generated:${NC} $f"
            
            # Parse and display summary (requires xmllint)
            if command -v xmllint &> /dev/null; then
                TOTAL=$(xmllint --xpath "string(//testsuite/@tests)" "$f" 2>/dev/null || echo "?")
                FAILURES=$(xmllint --xpath "string(//testsuite/@failures)" "$f" 2>/dev/null || echo "?")
                ERRORS=$(xmllint --xpath "string(//testsuite/@errors)" "$f" 2>/dev/null || echo "?")
                TIME=$(xmllint --xpath "string(//testsuite/@time)" "$f" 2>/dev/null || echo "?")
                
                echo -e "\n${YELLOW}Test Summary:${NC}"
                echo "Total Tests: $TOTAL"
                echo "Failures: $FAILURES" 
                echo "Errors: $ERRORS"
                echo "Time: ${TIME}s"
            fi
            break
        fi
    done
fi

# Create a simple HTML report if requested
if [ "$GENERATE_REPORT" = true ]; then
    cat > test_results/report.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Beat Racer Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .pass { color: green; }
        .fail { color: red; }
        .summary { background-color: #f0f0f0; padding: 10px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1>Beat Racer Test Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p>Generated: $(date)</p>
        <p>Exit Code: $EXIT_CODE</p>
    </div>
    <p>See JUnit XML Report for details.</p>
</body>
</html>
EOF
    echo -e "${YELLOW}HTML report generated:${NC} test_results/report.html"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Test run completed${NC}"
echo -e "${GREEN}========================================${NC}"

exit $EXIT_CODE