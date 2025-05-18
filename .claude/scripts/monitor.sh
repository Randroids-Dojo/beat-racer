#!/bin/bash

# Beat Racer Project Monitor Script
# Monitors for file changes and provides real-time analysis

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Initialize previous states
PREVIOUS_STATUS=""
PREVIOUS_FILES=""

echo -e "${GREEN}🚀 Beat Racer Project Monitor Started${NC}"
echo -e "${CYAN}Monitoring for changes every 30 seconds...${NC}"
echo "Press Ctrl+C to stop monitoring"
echo "========================================="

# Function to check which documentation needs updating
check_documentation_needs() {
    local changed_file=$1
    local docs_needed=()
    
    # Check file type and location
    if [[ $changed_file == *"scripts/autoloads/"* ]]; then
        docs_needed+=("project-structure.md")
    fi
    
    if [[ $changed_file == *"audio"* ]] || [[ $changed_file == *"sound"* ]]; then
        docs_needed+=("audio-implementation.md")
        docs_needed+=("critical-audio-notes.md")
    fi
    
    if [[ $changed_file == *"test"* ]]; then
        docs_needed+=("testing-debugging.md")
    fi
    
    if [[ $changed_file == *"scenes/"* ]]; then
        docs_needed+=("scene-composition.md")
    fi
    
    if [[ $changed_file == *"resources/"* ]]; then
        docs_needed+=("resource-management.md")
    fi
    
    echo "${docs_needed[@]}"
}

# Main monitoring loop
while true; do
    # Find recently modified files (last 30 seconds)
    RECENT_CHANGES=$(find . -type f -mmin -0.5 \
        -not -path "./.git/*" \
        -not -path "./.godot/*" \
        -not -path "./.claude/*" \
        -not -path "./test_results/*" \
        -not -name "*.tmp" \
        -not -name "*.uid" \
        2>/dev/null)
    
    # Get current git status
    GIT_STATUS=$(git status --porcelain)
    
    # Check if there are any changes
    if [[ "$RECENT_CHANGES" != "$PREVIOUS_FILES" ]] || [[ "$GIT_STATUS" != "$PREVIOUS_STATUS" ]]; then
        
        echo -e "\n${YELLOW}🔔 CHANGE DETECTED at $(date)${NC}"
        echo "========================================="
        
        # Report changed files
        if [[ -n "$RECENT_CHANGES" ]]; then
            echo -e "${BLUE}Recently modified files:${NC}"
            echo "$RECENT_CHANGES" | while read -r file; do
                echo "  📝 $file"
            done
        fi
        
        # Report git status changes
        if [[ "$GIT_STATUS" != "$PREVIOUS_STATUS" ]]; then
            echo -e "\n${PURPLE}Git status changes:${NC}"
            echo "$GIT_STATUS"
        fi
        
        # Analyze each changed file
        echo -e "\n${GREEN}Analysis:${NC}"
        
        # Get unique changed files from both sources
        ALL_CHANGES=$(echo -e "$RECENT_CHANGES\n$GIT_STATUS" | grep -E '\.gd$|\.tscn$|\.tres$|\.md$' | awk '{print $NF}' | sort -u)
        
        for file in $ALL_CHANGES; do
            if [[ -f "$file" ]]; then
                echo -e "\n${CYAN}File: $file${NC}"
                
                # Check documentation needs
                docs_needed=$(check_documentation_needs "$file")
                if [[ -n "$docs_needed" ]]; then
                    echo -e "${YELLOW}📚 Documentation to update:${NC}"
                    for doc in $docs_needed; do
                        echo "   - /docs/$doc"
                    done
                fi
                
                # Check file type specific issues
                if [[ $file == *.gd ]]; then
                    # Check for common code issues
                    if grep -q "print(" "$file"; then
                        echo -e "${YELLOW}⚠️  Contains print statements (consider using logger)${NC}"
                    fi
                    
                    if ! grep -q "extends" "$file"; then
                        echo -e "${RED}❌ Missing extends declaration${NC}"
                    fi
                    
                    if grep -q "AudioEffectDelay.*mix" "$file"; then
                        echo -e "${RED}❌ CRITICAL: AudioEffectDelay uses 'dry' not 'mix'!${NC}"
                    fi
                fi
                
                # Check for test coverage
                if [[ $file == *"scripts/"* ]] && [[ $file != *"test"* ]]; then
                    test_file="tests/gut/unit/test_$(basename $file)"
                    if [[ ! -f "$test_file" ]]; then
                        echo -e "${YELLOW}⚠️  No corresponding test file found${NC}"
                    fi
                fi
            fi
        done
        
        # Update states
        PREVIOUS_STATUS="$GIT_STATUS"
        PREVIOUS_FILES="$RECENT_CHANGES"
        
        echo -e "\n========================================="
        echo -e "${CYAN}Continuing to monitor...${NC}"
    fi
    
    sleep 30
done