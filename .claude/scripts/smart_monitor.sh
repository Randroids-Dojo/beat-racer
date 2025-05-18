#!/bin/bash

# Beat Racer Smart Project Monitor
# Provides real-time change detection with intelligent analysis

# State tracking
LAST_CHECK_TIME=$(date +%s)
PREVIOUS_HASHES=""

# Function to get file hash for change detection
get_file_hash() {
    find . -type f -name "*.gd" -o -name "*.tscn" -o -name "*.tres" -o -name "*.md" \
        -not -path "./.git/*" \
        -not -path "./.godot/*" \
        -not -path "./.claude/cache/*" \
        -exec stat -f "%m %N" {} \; 2>/dev/null | sort
}

# Function to analyze specific file
analyze_file() {
    local file=$1
    local analysis=""
    
    # File type analysis
    case "$file" in
        *.gd)
            analysis="GDScript file"
            # Check for common patterns
            if grep -q "extends Node" "$file"; then
                analysis="$analysis (Node script)"
            fi
            if grep -q "signal" "$file"; then
                analysis="$analysis [uses signals]"
            fi
            if grep -q "@export" "$file"; then
                analysis="$analysis [has exports]"
            fi
            ;;
        *.tscn)
            analysis="Scene file"
            ;;
        *.tres)
            analysis="Resource file"
            ;;
        *.md)
            analysis="Documentation file"
            ;;
    esac
    
    echo "$analysis"
}

# Function to suggest documentation updates
suggest_docs() {
    local file=$1
    local suggestions=()
    
    case "$file" in
        *audio*|*sound*)
            suggestions+=("audio-implementation.md")
            suggestions+=("critical-audio-notes.md")
            ;;
        *test*)
            suggestions+=("testing-debugging.md")
            ;;
        *ui*|*gui*)
            suggestions+=("ui-design.md")
            ;;
        *scene*)
            suggestions+=("scene-composition.md")
            ;;
        *resource*)
            suggestions+=("resource-management.md")
            ;;
        *signal*|*event*)
            suggestions+=("signal-management.md")
            ;;
    esac
    
    if [[ ${#suggestions[@]} -gt 0 ]]; then
        echo "UPDATE_DOCS: ${suggestions[*]}"
    fi
}

# Main monitoring function
monitor_changes() {
    local current_hashes=$(get_file_hash)
    
    if [[ "$current_hashes" != "$PREVIOUS_HASHES" ]]; then
        # Find what changed
        local changed_files=$(diff <(echo "$PREVIOUS_HASHES") <(echo "$current_hashes") | grep ">" | cut -d' ' -f3)
        
        if [[ -n "$changed_files" ]]; then
            echo "CHANGES_DETECTED"
            echo "$changed_files" | while read -r file; do
                if [[ -f "$file" ]]; then
                    echo "FILE: $file"
                    echo "TYPE: $(analyze_file "$file")"
                    echo "TIME: $(date +"%Y-%m-%d %H:%M:%S")"
                    suggest_docs "$file"
                    
                    # Git status for this file
                    git_status=$(git status --porcelain "$file" 2>/dev/null)
                    if [[ -n "$git_status" ]]; then
                        echo "GIT: $git_status"
                    fi
                    echo "---"
                fi
            done
        fi
        
        PREVIOUS_HASHES="$current_hashes"
    fi
}

# Run continuous monitoring
while true; do
    monitor_changes
    sleep 5  # Check every 5 seconds for more responsive monitoring
done