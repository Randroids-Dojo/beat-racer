#!/bin/bash

# Godot Error Checking Script for Beat Racer
# Provides comprehensive error detection and reporting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Beat Racer Error Checking Tool${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if Godot is available
if ! command -v godot &> /dev/null; then
    echo -e "${RED}Error: Godot not found in PATH${NC}"
    exit 1
fi

GODOT_VERSION=$(godot --version 2>/dev/null | head -n1)
echo -e "${BLUE}Found Godot: ${GODOT_VERSION}${NC}"
echo ""

# Create temporary files for different error types
TEMP_DIR=$(mktemp -d)
ALL_ERRORS="$TEMP_DIR/all_errors.txt"
PARSE_ERRORS="$TEMP_DIR/parse_errors.txt"
SCRIPT_ERRORS="$TEMP_DIR/script_errors.txt"
WARNINGS="$TEMP_DIR/warnings.txt"
TYPE_ERRORS="$TEMP_DIR/type_errors.txt"

# Function to clean up temporary files
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo -e "${YELLOW}Running comprehensive error check...${NC}"

# Run Godot error check and capture output
godot --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json --verbose 2>&1 > "$ALL_ERRORS" || true

# Extract different types of errors
grep "SCRIPT ERROR.*Parse Error" "$ALL_ERRORS" > "$PARSE_ERRORS" 2>/dev/null || true
grep "SCRIPT ERROR.*Compile Error" "$ALL_ERRORS" > "$SCRIPT_ERRORS" 2>/dev/null || true
grep "WARNING" "$ALL_ERRORS" > "$WARNINGS" 2>/dev/null || true
grep -E "(Cannot find member|Cannot infer the type|Value of type.*cannot be assigned)" "$ALL_ERRORS" > "$TYPE_ERRORS" 2>/dev/null || true

# Count errors
PARSE_COUNT=$(wc -l < "$PARSE_ERRORS" 2>/dev/null || echo "0")
SCRIPT_COUNT=$(wc -l < "$SCRIPT_ERRORS" 2>/dev/null || echo "0")
WARNING_COUNT=$(wc -l < "$WARNINGS" 2>/dev/null || echo "0")
TYPE_COUNT=$(wc -l < "$TYPE_ERRORS" 2>/dev/null || echo "0")

TOTAL_ERRORS=$((PARSE_COUNT + SCRIPT_COUNT + TYPE_COUNT))

echo ""
echo -e "${BLUE}========== ERROR SUMMARY ==========${NC}"
echo -e "Parse Errors:    ${RED}$PARSE_COUNT${NC}"
echo -e "Script Errors:   ${RED}$SCRIPT_COUNT${NC}"
echo -e "Type Errors:     ${RED}$TYPE_COUNT${NC}"
echo -e "Warnings:        ${YELLOW}$WARNING_COUNT${NC}"
echo -e "Total Errors:    ${RED}$TOTAL_ERRORS${NC}"
echo ""

# Show detailed errors if found
if [ "$TOTAL_ERRORS" -gt 0 ]; then
    echo -e "${RED}❌ ERRORS FOUND${NC}"
    echo ""
    
    if [ "$PARSE_COUNT" -gt 0 ]; then
        echo -e "${RED}📝 PARSE ERRORS:${NC}"
        # Clean up and show parse errors
        sed 's/\x1b\[[0-9;]*m//g' "$PARSE_ERRORS" | sed 's/^.*SCRIPT ERROR.*Parse Error: /❌ /' | head -10
        if [ "$PARSE_COUNT" -gt 10 ]; then
            echo "   ... and $((PARSE_COUNT - 10)) more parse errors"
        fi
        echo ""
    fi
    
    if [ "$TYPE_COUNT" -gt 0 ]; then
        echo -e "${RED}🔍 TYPE ERRORS:${NC}"
        sed 's/\x1b\[[0-9;]*m//g' "$TYPE_ERRORS" | sed 's/^.*SCRIPT ERROR.*Parse Error: /❌ /' | head -5
        if [ "$TYPE_COUNT" -gt 5 ]; then
            echo "   ... and $((TYPE_COUNT - 5)) more type errors"
        fi
        echo ""
    fi
    
    if [ "$SCRIPT_COUNT" -gt 0 ]; then
        echo -e "${RED}⚠️  COMPILE ERRORS:${NC}"
        sed 's/\x1b\[[0-9;]*m//g' "$SCRIPT_ERRORS" | sed 's/^.*SCRIPT ERROR.*Compile Error: /❌ /' | head -5
        echo ""
    fi
else
    echo -e "${GREEN}✅ NO ERRORS FOUND!${NC}"
fi

# Show warnings if present
if [ "$WARNING_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  WARNINGS ($WARNING_COUNT):${NC}"
    sed 's/\x1b\[[0-9;]*m//g' "$WARNINGS" | grep -v "Ignoring script.*because it does not extend GutTest" | head -5
    echo ""
fi

# Provide action recommendations
if [ "$TOTAL_ERRORS" -gt 0 ]; then
    echo -e "${BLUE}🔧 RECOMMENDED ACTIONS:${NC}"
    echo "1. Fix parse errors first (they prevent other scripts from loading)"
    echo "2. Address type inference issues"
    echo "3. Update GUT test assertions if using outdated syntax"
    echo "4. Check for missing enum members or class definitions"
    echo ""
    echo -e "${BLUE}💡 TIP: Run this script regularly during development${NC}"
    echo -e "${BLUE}💡 TIP: Add 'bash check_errors.sh' to your git pre-commit hook${NC}"
    
    exit 1
else
    echo -e "${GREEN}🎉 Project is error-free!${NC}"
    exit 0
fi