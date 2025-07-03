#!/bin/bash

# VLC Permanent Bookmarks Extension Debug Helper
# This script gathers debug information to help troubleshoot extension issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBUG_OUTPUT_DIR="$SCRIPT_DIR/debug_output"

echo -e "${BLUE}VLC Permanent Bookmarks Extension - Debug Helper${NC}"
echo "=================================================="
echo ""

# Create debug output directory
mkdir -p "$DEBUG_OUTPUT_DIR"

# Detect OS and set paths
OS="$(uname -s)"
case "${OS}" in
    Darwin*)
        PLATFORM="macOS"
        VLC_USER_DIR="$HOME/Library/Application Support/org.videolan.vlc"
        VLC_SYSTEM_DIR="/Applications/VLC.app/Contents/MacOS/share"
        VLC_CONFIG_DIR="$HOME/Library/Preferences"
        VLC_LOGS_DIR="$HOME/Library/Logs"
        ;;
    Linux*)
        PLATFORM="Linux"
        VLC_USER_DIR="$HOME/.local/share/vlc"
        VLC_SYSTEM_DIR="/usr/lib/vlc"
        VLC_CONFIG_DIR="$HOME/.config/vlc"
        VLC_LOGS_DIR="$HOME/.cache/vlc"
        # Check for Flatpak
        if [ -d "$HOME/.local/share/flatpak/app/org.videolan.VLC" ]; then
            VLC_FLATPAK_DIR="$HOME/.local/share/flatpak/app/org.videolan.VLC/x86_64/stable/active/files"
            echo -e "${YELLOW}Detected Flatpak VLC installation${NC}"
        fi
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS${NC}"
        exit 1
        ;;
esac

echo -e "${CYAN}Platform: $PLATFORM${NC}"
echo -e "${CYAN}Debug output directory: $DEBUG_OUTPUT_DIR${NC}"
echo ""

# Function to safely copy file with error handling
safe_copy() {
    local src="$1"
    local dst="$2"
    local desc="$3"
    
    if [ -f "$src" ]; then
        cp "$src" "$dst" 2>/dev/null && echo -e "${GREEN}✓ Copied $desc${NC}" || echo -e "${YELLOW}⚠ Failed to copy $desc${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ $desc not found: $src${NC}"
        return 1
    fi
}

# Function to safely list directory contents
safe_list() {
    local dir="$1"
    local desc="$2"
    local output_file="$3"
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓ Listing $desc${NC}"
        echo "=== $desc ===" >> "$output_file"
        echo "Directory: $dir" >> "$output_file"
        ls -la "$dir" >> "$output_file" 2>/dev/null || echo "Failed to list directory contents" >> "$output_file"
        echo "" >> "$output_file"
        return 0
    else
        echo -e "${YELLOW}⚠ $desc directory not found: $dir${NC}"
        echo "=== $desc ===" >> "$output_file"
        echo "Directory not found: $dir" >> "$output_file"
        echo "" >> "$output_file"
        return 1
    fi
}

# 1. Check extension installation
echo -e "${BLUE}1. Checking Extension Installation${NC}"
echo "=== Extension Installation Status ===" > "$DEBUG_OUTPUT_DIR/extension_status.txt"

# Check system installation
if [ -f "$VLC_SYSTEM_DIR/lua/extensions/vlc_permanents_bookmarks.lua" ]; then
    echo -e "${GREEN}✓ Extension found in system directory${NC}"
    echo "System installation: FOUND at $VLC_SYSTEM_DIR/lua/extensions/" >> "$DEBUG_OUTPUT_DIR/extension_status.txt"
    safe_copy "$VLC_SYSTEM_DIR/lua/extensions/vlc_permanents_bookmarks.lua" "$DEBUG_OUTPUT_DIR/installed_extension_system.lua" "system extension file"
else
    echo -e "${YELLOW}⚠ Extension not found in system directory${NC}"
    echo "System installation: NOT FOUND at $VLC_SYSTEM_DIR/lua/extensions/" >> "$DEBUG_OUTPUT_DIR/extension_status.txt"
fi

# Check user installation
if [ -f "$VLC_USER_DIR/lua/extensions/vlc_permanents_bookmarks.lua" ]; then
    echo -e "${GREEN}✓ Extension found in user directory${NC}"
    echo "User installation: FOUND at $VLC_USER_DIR/lua/extensions/" >> "$DEBUG_OUTPUT_DIR/extension_status.txt"
    safe_copy "$VLC_USER_DIR/lua/extensions/vlc_permanents_bookmarks.lua" "$DEBUG_OUTPUT_DIR/installed_extension_user.lua" "user extension file"
else
    echo -e "${YELLOW}⚠ Extension not found in user directory${NC}"
    echo "User installation: NOT FOUND at $VLC_USER_DIR/lua/extensions/" >> "$DEBUG_OUTPUT_DIR/extension_status.txt"
fi

# Check Flatpak installation (Linux only)
if [ "$PLATFORM" = "Linux" ] && [ -n "$VLC_FLATPAK_DIR" ]; then
    if [ -f "$VLC_FLATPAK_DIR/lib/vlc/lua/extensions/vlc_permanents_bookmarks.lua" ]; then
        echo -e "${GREEN}✓ Extension found in Flatpak directory${NC}"
        echo "Flatpak installation: FOUND" >> "$DEBUG_OUTPUT_DIR/extension_status.txt"
        safe_copy "$VLC_FLATPAK_DIR/lib/vlc/lua/extensions/vlc_permanents_bookmarks.lua" "$DEBUG_OUTPUT_DIR/installed_extension_flatpak.lua" "Flatpak extension file"
    else
        echo -e "${YELLOW}⚠ Extension not found in Flatpak directory${NC}"
        echo "Flatpak installation: NOT FOUND" >> "$DEBUG_OUTPUT_DIR/extension_status.txt"
    fi
fi

echo ""

# 2. Check VLC user data directories
echo -e "${BLUE}2. Checking VLC User Data Directories${NC}"
safe_list "$VLC_USER_DIR" "VLC user directory" "$DEBUG_OUTPUT_DIR/directory_listings.txt"
safe_list "$VLC_USER_DIR/lua" "VLC user Lua directory" "$DEBUG_OUTPUT_DIR/directory_listings.txt"
safe_list "$VLC_USER_DIR/lua/extensions" "VLC user extensions directory" "$DEBUG_OUTPUT_DIR/directory_listings.txt"
safe_list "$VLC_USER_DIR/lua/extensions/userdata" "VLC extensions userdata directory" "$DEBUG_OUTPUT_DIR/directory_listings.txt"

# Check for bookmark data directories
USERDATA_DIR="$HOME/.config/vlc"  # Default location
if [ "$PLATFORM" = "macOS" ]; then
    USERDATA_DIR="$HOME/Library/Application Support/org.videolan.vlc"
fi

# Look for VLC's userdata directory (where bookmarks should be stored)
VLC_USERDATA_PATHS=(
    "$USERDATA_DIR/lua/extensions/userdata/bookmarks"
    "$VLC_USER_DIR/lua/extensions/userdata/bookmarks"
    "$HOME/.local/share/vlc/lua/extensions/userdata/bookmarks"
    "$HOME/Library/Application Support/org.videolan.vlc/lua/extensions/userdata/bookmarks"
)

echo -e "${BLUE}3. Checking Bookmark Storage Directories${NC}"
echo "=== Bookmark Storage Directories ===" >> "$DEBUG_OUTPUT_DIR/directory_listings.txt"

for path in "${VLC_USERDATA_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo -e "${GREEN}✓ Found bookmark directory: $path${NC}"
        echo "FOUND: $path" >> "$DEBUG_OUTPUT_DIR/directory_listings.txt"
        safe_list "$path" "bookmark storage directory ($path)" "$DEBUG_OUTPUT_DIR/bookmark_files.txt"
        
        # Copy any bookmark files found
        find "$path" -name "*" -type f 2>/dev/null | while read -r file; do
            filename=$(basename "$file")
            safe_copy "$file" "$DEBUG_OUTPUT_DIR/bookmark_$filename" "bookmark file ($filename)"
        done
    else
        echo -e "${YELLOW}⚠ Bookmark directory not found: $path${NC}"
        echo "NOT FOUND: $path" >> "$DEBUG_OUTPUT_DIR/directory_listings.txt"
    fi
done

echo ""

# 4. Look for VLC logs and messages
echo -e "${BLUE}4. Gathering VLC Logs and Configuration${NC}"

# VLC preferences/config files
VLC_PREFS_PATHS=(
    "$HOME/Library/Preferences/org.videolan.vlc.plist"  # macOS
    "$HOME/.config/vlc/vlcrc"  # Linux
    "$HOME/.config/vlc/vlc-qt-interface.conf"  # Linux Qt
)

for pref_path in "${VLC_PREFS_PATHS[@]}"; do
    if [ -f "$pref_path" ]; then
        filename=$(basename "$pref_path")
        safe_copy "$pref_path" "$DEBUG_OUTPUT_DIR/vlc_config_$filename" "VLC config ($filename)"
    fi
done

# Look for VLC log files
VLC_LOG_PATHS=(
    "$HOME/Library/Logs/vlc.log"  # macOS
    "$HOME/.cache/vlc/logs/"  # Linux
    "$HOME/.local/share/vlc/logs/"  # Linux alternative
    "/tmp/vlc.log"  # Sometimes VLC logs here
)

for log_path in "${VLC_LOG_PATHS[@]}"; do
    if [ -f "$log_path" ]; then
        filename=$(basename "$log_path")
        safe_copy "$log_path" "$DEBUG_OUTPUT_DIR/vlc_log_$filename" "VLC log ($filename)"
    elif [ -d "$log_path" ]; then
        safe_list "$log_path" "VLC logs directory ($log_path)" "$DEBUG_OUTPUT_DIR/log_directories.txt"
        find "$log_path" -name "*.log" -type f 2>/dev/null | while read -r logfile; do
            filename=$(basename "$logfile")
            safe_copy "$logfile" "$DEBUG_OUTPUT_DIR/vlc_log_$filename" "VLC log ($filename)"
        done
    fi
done

echo ""

# 5. Create a VLC debug launcher script
echo -e "${BLUE}5. Creating VLC Debug Launcher${NC}"
cat > "$DEBUG_OUTPUT_DIR/launch_vlc_debug.sh" << 'EOF'
#!/bin/bash

# Launch VLC with debug output to capture extension messages
echo "Launching VLC with debug output..."
echo "Extension messages will be saved to vlc_debug_output.log"
echo "Press Ctrl+C to stop VLC and capture the log"
echo ""

if [ "$(uname)" = "Darwin" ]; then
    # macOS
    /Applications/VLC.app/Contents/MacOS/VLC --intf dummy --extraintf logger --verbose 2 --file-logging --logfile vlc_debug_output.log &
    VLC_PID=$!
    echo "VLC started with PID: $VLC_PID"
    echo "To stop VLC and capture logs, run: kill $VLC_PID"
elif [ "$(uname)" = "Linux" ]; then
    # Linux
    vlc --intf dummy --extraintf logger --verbose 2 --file-logging --logfile vlc_debug_output.log &
    VLC_PID=$!
    echo "VLC started with PID: $VLC_PID" 
    echo "To stop VLC and capture logs, run: kill $VLC_PID"
else
    echo "Unsupported platform for debug launcher"
    exit 1
fi
EOF

chmod +x "$DEBUG_OUTPUT_DIR/launch_vlc_debug.sh"
echo -e "${GREEN}✓ Created VLC debug launcher${NC}"

# 6. Create system info summary
echo -e "${BLUE}6. Creating System Information Summary${NC}"
cat > "$DEBUG_OUTPUT_DIR/system_info.txt" << EOF
=== System Information ===
OS: $OS ($PLATFORM)
Date: $(date)
VLC User Directory: $VLC_USER_DIR
VLC System Directory: $VLC_SYSTEM_DIR
Current Working Directory: $SCRIPT_DIR

=== VLC Installation Check ===
EOF

# Check if VLC is installed and get version
if command -v vlc >/dev/null 2>&1; then
    echo "VLC Command Available: YES" >> "$DEBUG_OUTPUT_DIR/system_info.txt"
    vlc --version 2>/dev/null | head -n 3 >> "$DEBUG_OUTPUT_DIR/system_info.txt" || echo "Could not get VLC version" >> "$DEBUG_OUTPUT_DIR/system_info.txt"
elif [ -f "/Applications/VLC.app/Contents/MacOS/VLC" ]; then
    echo "VLC Command Available: NO (but app bundle found on macOS)" >> "$DEBUG_OUTPUT_DIR/system_info.txt"
    /Applications/VLC.app/Contents/MacOS/VLC --version 2>/dev/null | head -n 3 >> "$DEBUG_OUTPUT_DIR/system_info.txt" || echo "Could not get VLC version" >> "$DEBUG_OUTPUT_DIR/system_info.txt"
else
    echo "VLC Command Available: NO" >> "$DEBUG_OUTPUT_DIR/system_info.txt"
fi

# 7. Create extension test script
echo -e "${BLUE}7. Creating Extension Test Script${NC}"
cat > "$DEBUG_OUTPUT_DIR/test_extension_syntax.lua" << 'EOF'
-- Simple Lua syntax test for the VLC extension
-- This script will test if the extension has any syntax errors

print("Testing VLC Permanent Bookmarks Extension...")

-- Load the extension file
local extension_file = "../vlc_permanents_bookmarks.lua"

local function test_syntax()
    local f = io.open(extension_file, "r")
    if not f then
        print("ERROR: Could not open extension file: " .. extension_file)
        return false
    end
    
    local content = f:read("*all")
    f:close()
    
    -- Try to compile the Lua code
    local func, err = load(content, extension_file)
    if not func then
        print("SYNTAX ERROR in extension:")
        print(err)
        return false
    end
    
    print("✓ Extension syntax is valid")
    return true
end

-- Test the syntax
local success = test_syntax()
if success then
    print("✓ Extension file appears to be syntactically correct")
    os.exit(0)
else
    print("✗ Extension file has syntax errors")
    os.exit(1)
end
EOF

# Test extension syntax
echo -e "${CYAN}Testing extension syntax...${NC}"
if command -v lua >/dev/null 2>&1; then
    cd "$DEBUG_OUTPUT_DIR"
    if lua test_extension_syntax.lua; then
        echo -e "${GREEN}✓ Extension syntax test passed${NC}"
    else
        echo -e "${RED}✗ Extension syntax test failed${NC}"
    fi
    cd "$SCRIPT_DIR"
else
    echo -e "${YELLOW}⚠ Lua interpreter not available for syntax testing${NC}"
fi

echo ""
echo -e "${GREEN}=== Debug Information Collection Complete ===${NC}"
echo ""
echo -e "${CYAN}Debug files created in: $DEBUG_OUTPUT_DIR${NC}"
echo ""
echo -e "${BLUE}Next steps for debugging:${NC}"
echo "1. Check the files in $DEBUG_OUTPUT_DIR for clues"
echo "2. Run: $DEBUG_OUTPUT_DIR/launch_vlc_debug.sh"
echo "3. Open a media file in VLC"
echo "4. Try to use the bookmark extension"
echo "5. Stop VLC and check vlc_debug_output.log for messages"
echo ""
echo -e "${YELLOW}Key files to examine:${NC}"
echo "• extension_status.txt - Extension installation status"
echo "• system_info.txt - System and VLC information"
echo "• directory_listings.txt - VLC directory structure"
echo "• bookmark_files.txt - Existing bookmark files (if any)"
echo "• vlc_config_* - VLC configuration files"
echo "• vlc_log_* - Existing VLC log files"
echo ""
echo -e "${CYAN}To view all collected information:${NC}"
echo "ls -la $DEBUG_OUTPUT_DIR"
echo "cat $DEBUG_OUTPUT_DIR/*.txt" 