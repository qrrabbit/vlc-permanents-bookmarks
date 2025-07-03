#!/bin/bash

# Review Debug Output Script
# This script displays the debug information collected by debug_vlc.sh

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

echo -e "${BOLD}${BLUE}VLC Extension Debug Information Review${NC}"
echo "========================================="
echo ""

if [ ! -d "$DEBUG_DIR" ]; then
    echo -e "${RED}Debug directory not found: $DEBUG_DIR${NC}"
    echo "Please run ./debug_vlc.sh first to collect debug information."
    exit 1
fi

echo -e "${CYAN}Debug directory: $DEBUG_DIR${NC}"
echo ""

# Function to display file content with header
show_file() {
    local file="$1"
    local title="$2"
    
    if [ -f "$DEBUG_DIR/$file" ]; then
        echo -e "${BOLD}${GREEN}=== $title ===${NC}"
        cat "$DEBUG_DIR/$file"
        echo ""
    else
        echo -e "${YELLOW}⚠ $title file not found: $file${NC}"
        echo ""
    fi
}

# Function to show file if it exists, with size info
show_file_info() {
    local file="$1"
    local desc="$2"
    
    if [ -f "$DEBUG_DIR/$file" ]; then
        local size=$(wc -l < "$DEBUG_DIR/$file" 2>/dev/null || echo "?")
        echo -e "${GREEN}✓ $desc ($size lines)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ $desc - not found${NC}"
        return 1
    fi
}

# 1. Show available debug files
echo -e "${BOLD}${BLUE}Available Debug Files:${NC}"
show_file_info "system_info.txt" "System Information"
show_file_info "extension_status.txt" "Extension Installation Status"
show_file_info "directory_listings.txt" "Directory Listings"
show_file_info "bookmark_files.txt" "Bookmark Files"
show_file_info "vlc_debug_output.log" "VLC Debug Log"

# Check for copied extension files
for ext_file in "$DEBUG_DIR"/installed_extension_*.lua; do
    if [ -f "$ext_file" ]; then
        filename=$(basename "$ext_file")
        echo -e "${GREEN}✓ Installed Extension Copy: $filename${NC}"
    fi
done

# Check for bookmark files
for bookmark_file in "$DEBUG_DIR"/bookmark_*; do
    if [ -f "$bookmark_file" ] && [[ ! "$bookmark_file" == *".txt" ]]; then
        filename=$(basename "$bookmark_file")
        echo -e "${GREEN}✓ Bookmark Data: $filename${NC}"
    fi
done

echo ""

# 2. Display key information
show_file "system_info.txt" "System Information"
show_file "extension_status.txt" "Extension Installation Status"
show_file "directory_listings.txt" "VLC Directory Structure"

# 3. Show VLC debug log if available
if [ -f "$DEBUG_DIR/vlc_debug_output.log" ]; then
    echo -e "${BOLD}${GREEN}=== VLC Debug Log (last 50 lines) ===${NC}"
    tail -n 50 "$DEBUG_DIR/vlc_debug_output.log"
    echo ""
    echo -e "${CYAN}Full log available at: $DEBUG_DIR/vlc_debug_output.log${NC}"
    echo ""
fi

# 4. Check for specific error patterns in logs
echo -e "${BOLD}${BLUE}Checking for Common Issues:${NC}"
echo ""

# Check if extension is being loaded
FOUND_ISSUES=0

if [ -f "$DEBUG_DIR/vlc_debug_output.log" ]; then
    if grep -i "bookmark" "$DEBUG_DIR/vlc_debug_output.log" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Extension appears to be detected by VLC${NC}"
    else
        echo -e "${RED}✗ No bookmark extension references found in VLC log${NC}"
        FOUND_ISSUES=1
    fi
    
    if grep -i "error\|fail\|exception" "$DEBUG_DIR/vlc_debug_output.log" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Errors found in VLC log:${NC}"
        grep -i "error\|fail\|exception" "$DEBUG_DIR/vlc_debug_output.log" | head -n 5
        echo ""
        FOUND_ISSUES=1
    fi
    
    if grep -i "lua" "$DEBUG_DIR/vlc_debug_output.log" >/dev/null 2>&1; then
        echo -e "${CYAN}Lua-related messages found:${NC}"
        grep -i "lua" "$DEBUG_DIR/vlc_debug_output.log" | head -n 10
        echo ""
    fi
else
    echo -e "${YELLOW}⚠ No VLC debug log found - run the debug launcher first${NC}"
fi

# Check extension syntax
if [ -f "$DEBUG_DIR/test_extension_syntax.lua" ]; then
    echo -e "${CYAN}Testing extension syntax...${NC}"
    if command -v lua >/dev/null 2>&1; then
        cd "$DEBUG_DIR"
        if lua test_extension_syntax.lua 2>/dev/null; then
            echo -e "${GREEN}✓ Extension syntax is valid${NC}"
        else
            echo -e "${RED}✗ Extension has syntax errors${NC}"
            lua test_extension_syntax.lua
            FOUND_ISSUES=1
        fi
        cd "$SCRIPT_DIR"
    else
        echo -e "${YELLOW}⚠ Lua interpreter not available for syntax testing${NC}"
    fi
fi

echo ""

# 5. Summary and recommendations
echo -e "${BOLD}${BLUE}Summary and Recommendations:${NC}"
echo ""

if [ $FOUND_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ No obvious issues found in the collected debug information${NC}"
    echo ""
    echo -e "${CYAN}Recommended next steps:${NC}"
    echo "1. Run VLC with debug logging: $DEBUG_DIR/launch_vlc_debug.sh"
    echo "2. Open a media file and try to use the extension"
    echo "3. Check the generated vlc_debug_output.log for detailed messages"
    echo "4. Look for specific error messages when clicking 'Add' button"
else
    echo -e "${RED}⚠ Issues found - see details above${NC}"
    echo ""
    echo -e "${CYAN}Recommended actions:${NC}"
    echo "1. Fix any syntax errors in the extension"
    echo "2. Check VLC installation and extension placement"
    echo "3. Verify VLC can load Lua extensions"
fi

echo ""
echo -e "${BOLD}${CYAN}To get real-time debug output:${NC}"
echo "1. Run: $DEBUG_DIR/launch_vlc_debug.sh"
echo "2. Open VLC normally (in addition to the debug instance)"
echo "3. Load a media file and try the extension"
echo "4. Check vlc_debug_output.log for messages"
echo ""
echo -e "${BOLD}${CYAN}All debug files are in: $DEBUG_DIR${NC}" 