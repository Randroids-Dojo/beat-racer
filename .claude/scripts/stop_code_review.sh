#!/bin/bash
# chmod +x applied

# This script will stop the code review monitor

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Find and kill the monitor process
MONITOR_PID=$(ps -ef | grep "code_review_monitor.sh" | grep -v grep | awk '{print $2}')

if [ -z "$MONITOR_PID" ]; then
    echo -e "${YELLOW}No code review monitor process found running.${NC}"
    exit 0
fi

echo -e "${GREEN}Stopping code review monitor process (PID: $MONITOR_PID)...${NC}"
kill $MONITOR_PID

# Check if the process was killed
sleep 1
if ps -p $MONITOR_PID > /dev/null 2>&1; then
    echo -e "${YELLOW}Failed to stop the process. Trying force kill...${NC}"
    kill -9 $MONITOR_PID
    sleep 1
    if ps -p $MONITOR_PID > /dev/null 2>&1; then
        echo -e "${RED}Failed to force kill the process.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Code review monitor stopped successfully.${NC}"
exit 0

