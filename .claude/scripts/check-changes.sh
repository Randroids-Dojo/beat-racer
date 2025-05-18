#!/bin/bash

# Beat Racer Change Checker - One-shot analysis

echo "🔍 Checking for changes in Beat Racer project..."
echo "Time: $(date +%H:%M:%S)"
echo "========================================="

# Check git status
echo "📊 Git Status:"
git status --porcelain
echo ""

# Check recently modified files (last 5 minutes)
echo "📝 Recently Modified Files (last 5 min):"
find . -type f -mmin -5 \
    -not -path "./.git/*" \
    -not -path "./.godot/*" \
    -not -path "./test_results/*" \
    -not -name "*.tmp" \
    -not -name "*.uid" \
    \( -name "*.gd" -o -name "*.tscn" -o -name "*.tres" -o -name "*.md" \) \
    -exec echo "  - {}" \;

echo ""

# Check current story
echo "📖 Current Story:"
grep -A5 "Story [0-9]\+:" backlog.md | grep -v "^-\s*\[x\]" | grep "^-\s*\[\s\]" | head -1 || echo "  No current story found"

echo ""
echo "========================================="