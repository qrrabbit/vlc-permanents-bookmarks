#!/bin/bash

# VLC Permanent Bookmarks Extension Deployment Script
# This script copies the extension to the appropriate VLC extensions directory

set -e  # Exit on any error

EXTENSION_FILE="vlc_permanents_bookmarks.lua"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/$EXTENSION_FILE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}VLC Permanent Bookmarks Extension Deployment Script${NC}"
echo "=================================================="

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo -e "${RED}Error: $EXTENSION_FILE not found in current directory${NC}"
    exit 1
fi

# Detect operating system
OS="$(uname -s)"
case "${OS}" in
    Linux*)
        PLATFORM=Linux
        # Try to detect if it's a flatpak installation first
        if [ -d "$HOME/.local/share/flatpak/app/org.videolan.VLC" ]; then
            echo -e "${YELLOW}Detected Flatpak VLC installation${NC}"
            DEST_DIR="$HOME/.local/share/flatpak/app/org.videolan.VLC/x86_64/stable/active/files/lib/vlc/lua/extensions"
            INSTALL_TYPE="flatpak"
        else
            # Check for system-wide installation
            if [ -d "/usr/lib/vlc/lua" ]; then
                echo -e "${YELLOW}Detected system-wide VLC installation${NC}"
                DEST_DIR="/usr/lib/vlc/lua/extensions"
                INSTALL_TYPE="system"
            else
                # Fall back to user directory
                echo -e "${YELLOW}Using user directory for VLC extensions${NC}"
                DEST_DIR="$HOME/.local/share/vlc/lua/extensions"
                INSTALL_TYPE="user"
            fi
        fi
        ;;
    Darwin*)
        PLATFORM=macOS
        # Check for system-wide installation first
        if [ -d "/Applications/VLC.app" ]; then
            echo -e "${YELLOW}Detected system-wide VLC installation on macOS${NC}"
            DEST_DIR="/Applications/VLC.app/Contents/MacOS/share/lua/extensions"
            INSTALL_TYPE="system"
        else
            # Fall back to user directory
            echo -e "${YELLOW}Using user directory for VLC extensions${NC}"
            DEST_DIR="$HOME/Library/Application Support/org.videolan.vlc/lua/extensions"
            INSTALL_TYPE="user"
        fi
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        PLATFORM=Windows
        echo -e "${YELLOW}Windows detected - using user AppData directory${NC}"
        DEST_DIR="$APPDATA/vlc/lua/extensions"
        INSTALL_TYPE="user"
        ;;
    *)
        echo -e "${RED}Unsupported operating system: ${OS}${NC}"
        exit 1
        ;;
esac

echo "Platform: $PLATFORM"
echo "Install type: $INSTALL_TYPE"
echo "Destination: $DEST_DIR"
echo ""

# Create destination directory if it doesn't exist
echo -e "${BLUE}Creating destination directory...${NC}"
if [ "$INSTALL_TYPE" = "system" ] && [ "$PLATFORM" = "macOS" ]; then
    # For macOS system installation, we might need sudo
    if [ ! -w "$(dirname "$DEST_DIR")" ]; then
        echo -e "${YELLOW}System directory requires admin privileges${NC}"
        sudo mkdir -p "$DEST_DIR"
    else
        mkdir -p "$DEST_DIR"
    fi
elif [ "$INSTALL_TYPE" = "system" ] && [ "$PLATFORM" = "Linux" ]; then
    # For Linux system installation, we need sudo
    echo -e "${YELLOW}System directory requires admin privileges${NC}"
    sudo mkdir -p "$DEST_DIR"
else
    # User directories
    mkdir -p "$DEST_DIR"
fi

# Copy the file
echo -e "${BLUE}Copying extension file...${NC}"
if [ "$INSTALL_TYPE" = "system" ] && [ "$PLATFORM" = "macOS" ] && [ ! -w "$DEST_DIR" ]; then
    sudo cp "$SOURCE_FILE" "$DEST_DIR/"
    echo -e "${GREEN}✓ Extension copied with admin privileges${NC}"
elif [ "$INSTALL_TYPE" = "system" ] && [ "$PLATFORM" = "Linux" ]; then
    sudo cp "$SOURCE_FILE" "$DEST_DIR/"
    echo -e "${GREEN}✓ Extension copied with admin privileges${NC}"
else
    cp "$SOURCE_FILE" "$DEST_DIR/"
    echo -e "${GREEN}✓ Extension copied${NC}"
fi

# Verify the copy
if [ -f "$DEST_DIR/$EXTENSION_FILE" ]; then
    echo -e "${GREEN}✓ Verification successful - extension installed at:${NC}"
    echo "  $DEST_DIR/$EXTENSION_FILE"
else
    echo -e "${RED}✗ Verification failed - extension not found at destination${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Restart VLC if it's currently running"
echo "2. Open a media file in VLC"
echo "3. Go to View > Extensions > VLC Permanents Bookmarks (or VLC > Extensions on macOS)"
echo "4. Start adding bookmarks!"
echo ""
echo -e "${YELLOW}Note: If you don't see the extension in the menu, check VLC's Messages log${NC}"
echo -e "${YELLOW}(Tools > Messages) for any error messages.${NC}" 