#!/bin/bash
# chmod +x applied

# Beat Racer Project Code Review Monitor
# Monitors for file changes and sends them to Claude Code for review

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration - edit these values as needed
INTERVAL=10 # Check interval in seconds
PROJECT_ROOT="/Users/randroid/Dev/Games/beat-racer"
CODE_REVIEW_BUFFER_FILE="/tmp/claude_code_review_buffer.txt"

# File patterns to track (focus on what matters for code review)
INCLUDE_PATTERNS="*.gd *.tscn *.tres *.shader *.json *.cfg"

# File patterns to exclude
EXCLUDE_DIRS=".git .godot .claude test_results"
EXCLUDE_FILES="*.tmp *.uid *.import"

# Initialize state
PREVIOUS_CHANGED_FILES=""

echo -e "${GREEN}🚀 Beat Racer Project Code Review Monitor Started${NC}"
echo -e "${CYAN}Monitoring for changes every $INTERVAL seconds...${NC}"
echo "Press Ctrl+C to stop monitoring"
echo "========================================="

# Function to build find command with patterns
build_find_command() {
    local cmd="find $PROJECT_ROOT -type f"
    
    # Add file patterns to include using -o for OR logic
    cmd+=" \( -name \"*.gd\" -o -name \"*.tscn\" -o -name \"*.tres\" -o -name \"*.shader\" -o -name \"*.json\" -o -name \"*.cfg\" \)"
    
    # Add paths to exclude
    for dir in $EXCLUDE_DIRS; do
        cmd+=" -not -path \"$PROJECT_ROOT/$dir/*\""
    done
    
    # Add file patterns to exclude
    for pattern in $EXCLUDE_FILES; do
        cmd+=" -not -name \"$pattern\""
    done
    
    echo "$cmd"
}

# Function to send file to Claude Code for review
send_to_claude_code() {
    local file=$1
    local rel_path=${file#"$PROJECT_ROOT/"}
    
    echo -e "\n${CYAN}Sending $rel_path to Claude Code for review...${NC}"
    claude /project:review_changes "$file"
}

# Function to get modification time of a file
get_mod_time() {
    stat -f "%m" "$1" 2>/dev/null || echo "0"
}

# Function to store previous modification times
store_mod_times() {
    find_cmd=$(build_find_command)
    files=$(eval "$find_cmd")
    
    > "/tmp/beat_racer_mod_times.txt"
    
    for file in $files; do
        echo "$file:$(get_mod_time "$file")" >> "/tmp/beat_racer_mod_times.txt"
    done
}
# Hello
# Function to create a test file for verification
create_test_file() {
    echo "Creating a temporary test file to verify monitoring..."
    local test_dir="$PROJECT_ROOT/tests/monitoring"
    mkdir -p "$test_dir"
    local test_file="$test_dir/monitoring_test_$(date +%s).gd"
    
    cat > "$test_file" << EOF
extends Node

# Test file created by code review monitor
# This file was automatically generated to verify that file monitoring is working

func _ready():
	print("Test file generated at $(date)")
	# This print statement should trigger a review comment
EOF
    
    echo "Created test file: ${test_file#"$PROJECT_ROOT/"}"
    echo "Waiting for next monitoring cycle to detect it..."
    echo "$test_file"
}

# Ask if user wants to create a test file
echo -e "${YELLOW}Would you like to create a test file to verify monitoring? (y/n)${NC}"
read -r -n 1 create_test
echo ""

# Let's add a slight delay after creating the test file to ensure it's picked up
if [[ "$create_test" =~ ^[Yy]$ ]]; then
    TEST_FILE=$(create_test_file)
    sleep 2  # Short delay to ensure the file is fully written
fi

# Initialize modification times
store_mod_times
echo -e "${GREEN}Initial file state recorded.${NC}"

# Main monitoring loop
while true; do
    # Store current mod times to a new file
    > "/tmp/beat_racer_new_mod_times.txt"
    
    find_cmd=$(build_find_command)
    files=$(eval "$find_cmd")
    
    for file in $files; do
        echo "$file:$(get_mod_time "$file")" >> "/tmp/beat_racer_new_mod_times.txt"
    done
    
    # Find differences
    echo "Looking for changes..."
    CHANGED_FILES=$(comm -13 <(sort "/tmp/beat_racer_mod_times.txt") <(sort "/tmp/beat_racer_new_mod_times.txt") | cut -d':' -f1)
    
    # Debug information
    if [[ -n "$CHANGED_FILES" ]]; then
        echo "DEBUG: Found changes in these files:"
        echo "$CHANGED_FILES"
    else
        echo "DEBUG: No changes found this round"
    fi
    
    # Check if there are any changes
    if [[ -n "$CHANGED_FILES" ]] && [[ "$CHANGED_FILES" != "$PREVIOUS_CHANGED_FILES" ]]; then
        echo -e "\n${YELLOW}🔔 CODE CHANGES DETECTED at $(date)${NC}"
        echo "========================================="
        
        # Convert changed files string to array more safely
        changed_files_array=()
        while IFS= read -r line; do
            changed_files_array+=("$line")
        done <<< "$CHANGED_FILES"
        
        # Display the number of changed files
        echo -e "${GREEN}Number of changed files: ${#changed_files_array[@]}${NC}"
        
        # Process each changed file
        for file in "${changed_files_array[@]}"; do
            if [[ -f "$file" ]]; then
                rel_path=${file#"$PROJECT_ROOT/"}
                echo -e "${BLUE}Changed file: $rel_path${NC}"
                
                # Send to Claude Code for review
                send_to_claude_code "$file"
            else
                echo -e "${RED}File no longer exists: $file${NC}"
            fi
        done
        
        # Update previous state
        PREVIOUS_CHANGED_FILES="$CHANGED_FILES"
        
        echo -e "\n========================================="
        echo -e "${CYAN}Continuing to monitor...${NC}"
    fi
    
    # Update stored mod times
    mv "/tmp/beat_racer_new_mod_times.txt" "/tmp/beat_racer_mod_times.txt"
    
    sleep $INTERVAL
done
