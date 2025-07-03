#!/bin/bash

# Monitor VLC Debug Output
# This script helps monitor and analyze the VLC debug log in real-time

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBUG_DIR="$SCRIPT_DIR/debug_output"
LOG_FILE="$DEBUG_DIR/vlc_debug_output.log"

echo -e "${BOLD}${BLUE}VLC Debug Output Monitor${NC}"
echo "========================="
echo ""

if [ ! -f "$LOG_FILE" ]; then
    echo -e "${YELLOW}⚠ Debug log not found yet: $LOG_FILE${NC}"
    echo "Please ensure VLC debug launcher is running:"
    echo "cd debug_output && ./launch_vlc_debug.sh"
    echo ""
    echo "Waiting for log file to appear..."
    
    # Wait for log file to appear (up to 30 seconds)
    for i in {1..30}; do
        if [ -f "$LOG_FILE" ]; then
            echo -e "${GREEN}✓ Log file appeared!${NC}"
            break
        fi
        sleep 1
        echo -n "."
    done
    echo ""
fi

if [ ! -f "$LOG_FILE" ]; then
    echo -e "${RED}✗ Log file still not found. Please check VLC debug launcher.${NC}"
    exit 1
fi

echo -e "${CYAN}Monitoring VLC debug log: $LOG_FILE${NC}"
echo -e "${YELLOW}Instructions:${NC}"
echo "1. Open a media file in VLC (regular VLC, not the debug instance)"
echo "2. Go to View > Extensions > VLC Permanents Bookmarks"
echo "3. Try to add a bookmark"
echo "4. Watch this output for relevant messages"
echo "5. Press Ctrl+C to stop monitoring"
echo ""
echo -e "${BOLD}${GREEN}=== Debug Output (filtering for bookmark/extension messages) ===${NC}"
echo ""

# Function to filter and highlight relevant log messages
filter_log() {
    while IFS= read -r line; do
        # Color-code different message types
        if echo "$line" | grep -qi "bookmark\|extension"; then
            echo -e "${GREEN}[EXTENSION] $line${NC}"
        elif echo "$line" | grep -qi "error\|fail"; then
            echo -e "${RED}[ERROR] $line${NC}"
        elif echo "$line" | grep -qi "warn"; then
            echo -e "${YELLOW}[WARNING] $line${NC}"
        elif echo "$line" | grep -qi "lua"; then
            echo -e "${CYAN}[LUA] $line${NC}"
        elif echo "$line" | grep -qi "debug\|dbg"; then
            echo -e "${BLUE}[DEBUG] $line${NC}"
        else
            # Still show the line but dimmed
            echo -e "\033[2m$line${NC}"
        fi
    done
}

# Monitor the log file
tail -f "$LOG_FILE" | filter_log 