# VLC Permanent Bookmarks Extension

A comprehensive VLC extension for permanently saving and managing media bookmarks with advanced debugging tools and cross-platform deployment automation.

## Project History

This project started from a broken VLC bookmarks extension that showed a popup dialog but had non-functional "Add" button. Through extensive debugging and development, we completely rebuilt the extension with:

- ✅ **Working bookmark functionality** - Add, rename, remove, and navigate bookmarks
- ✅ **Permanent storage** - Bookmarks persist across VLC sessions using file hash association
- ✅ **Cross-platform deployment** - Automated installation scripts for Windows, macOS, and Linux
- ✅ **Comprehensive debugging tools** - Advanced logging and system analysis utilities
- ✅ **Clean, maintainable code** - Streamlined implementation with proper error handling

## Features

### Core Functionality
- **Permanent Bookmark Storage**: Bookmarks are saved permanently using media file hash identification
- **Cross-Session Persistence**: Bookmarks survive VLC restarts and file relocations
- **Hash-Based Association**: Works even if media files are moved or renamed (content unchanged)
- **Multiple Operations**: Add, rename, remove, and navigate to bookmarks
- **Smart Duplicate Handling**: Updates existing bookmarks at same time position instead of creating duplicates
- **Instant Navigation**: "Go" button jumps to bookmark and closes dialog automatically

### User Interface
- **Clean Dialog Layout**: Minimalist design optimized for VLC's dialog system limitations
- **Sequential Bookmark Display**: Bookmarks shown in chronological order
- **Contextual Footer Messages**: Real-time feedback for all operations
- **Consecutive Removal Support**: Auto-selection for multiple bookmark removals
- **Input Validation**: Comprehensive error checking and user feedback

### Technical Improvements
- **Ultra-Minimal Grid Layout**: Bypasses VLC's dialog positioning bugs
- **Robust Error Handling**: Graceful handling of edge cases and system errors
- **Memory Management**: Proper cleanup and garbage collection
- **Cross-Platform File Paths**: Automatic detection of VLC installation directories

## Installation

### Option 1: Automated Installation (Recommended)

#### Using Make Commands (Cross-Platform)
```bash
# Quick install with auto-detection
make install

# Install for all users (requires admin/sudo)
make install-system

# Install for current user only  
make install-user

# Test extension accessibility
make test

# Debug mode with comprehensive logging
make debug

# Remove extension
make clean
```

#### Using Deployment Script
```bash
# Direct script execution
./deploy.sh

# Or make it executable first
chmod +x deploy.sh
./deploy.sh
```

### Option 2: Manual Installation

Download `vlc_permanents_bookmarks.lua` and place it in your VLC extensions directory:

#### Windows
- **All users**: `%ProgramFiles%\VideoLAN\VLC\lua\extensions\`
- **Current user**: `%APPDATA%\VLC\lua\extensions\`

#### macOS
- **All users**: `/Applications/VLC.app/Contents/MacOS/share/lua/extensions/`
- **Current user**: `~/Library/Application Support/org.videolan.vlc/lua/extensions/`

#### Linux
- **All users**: `/usr/lib/vlc/lua/extensions/`
- **Current user**: `~/.local/share/vlc/lua/extensions/`
- **Flatpak**: `~/.local/share/flatpak/app/org.videolan.VLC/x86_64/stable/active/files/lib/vlc/lua/extensions/`

## Usage

1. **Start VLC** and open any media file (video, audio, network stream)
2. **Access Extension**: 
   - **Windows/Linux**: `View → Bookmarks`
   - **macOS**: `VLC → Extensions → VLC Permanents Bookmarks`
3. **Add Bookmarks**: Type description and click "Add"
4. **Navigate**: Select bookmark and click "Go" (jumps to time and closes dialog)
5. **Manage**: Use "Rename" and "Remove" buttons for bookmark management

## Known Limitations

### VLC 3.0.18 Dialog System Constraints

Due to VLC's Lua extension API limitations, several advanced features could not be implemented:

#### Keyboard Input Limitations
- **ENTER Key**: VLC captures and suppresses ENTER key events with no API for extensions to receive them
- **Tab Navigation**: VLC buttons are not focusable via Tab key navigation
- **Keyboard Shortcuts**: No support for custom keyboard shortcuts in extension dialogs

#### UI Interaction Limitations  
- **List Selection Callbacks**: No callbacks available for list widget selection events
- **Double-Click Detection**: No support for double-click events on list widgets
- **Auto-Population**: Cannot automatically populate text input when selecting bookmarks

#### Dialog Sizing Issues
- **Fixed Width**: Dialog width is content-driven with no direct size control API
- **Grid Layout Bugs**: VLC's grid positioning system has anchoring issues requiring ultra-minimal spans
- **Responsive Design**: Limited ability to create adaptive layouts

#### Technical References
These limitations are documented VLC issues affecting extension development:
- [VLC Extension Dialog System Limitations](https://code.videolan.org/videolan/vlc/-/tree/master/share/lua) - Official VLC Lua documentation
- [VLC Forum: Dialog System Constraints](https://forum.videolan.org/viewforum.php?f=29) - Community discussions on extension limitations

## Project Files

### Core Extension
- **`vlc_permanents_bookmarks.lua`** - Main extension file with bookmark functionality

### Deployment & Build System
- **`Makefile`** - Cross-platform build automation with install, test, debug targets
- **`deploy.sh`** - Standalone deployment script with auto-detection
- **`deploy`** - Symlink to deploy.sh for convenience

### Configuration & Fixes
- **`vlc_config_fix.txt`** - VLC configuration recommendations and known issue workarounds

### Debug & Analysis Tools
- **`debug_vlc.sh`** - Comprehensive VLC debugging with log capture and system analysis
- **`monitor_debug.sh`** - Real-time debug monitoring with filtered output
- **`review_debug.sh`** - Debug log analysis and troubleshooting assistance

### Debug Output Directory (`debug_output/`)
- **`vlc_debug_output.log`** - Complete VLC debug session logs
- **`launch_vlc_debug.sh`** - VLC launcher with debug output redirection
- **`system_info.txt`** - System and VLC version information
- **`extension_status.txt`** - Extension loading and status verification
- **`directory_listings.txt`** - VLC installation directory analysis
- **`bookmark_files.txt`** - Bookmark file location and content analysis
- **`test_extension_syntax.lua`** - Minimal extension for syntax validation
- **`installed_extension_system.lua`** - System extension analysis for comparison
- **`vlc_config_org.videolan.vlc.plist`** - macOS VLC configuration backup
- **`bookmark_eb601ca8fe5db9cb`** - Sample bookmark file for testing

## Development Tools

### Debugging Workflow
```bash
# Start comprehensive debugging session
make debug

# Monitor extension in real-time  
make monitor-debug

# Review debug logs for issues
make review-debug

# Test extension syntax and loading
make test
```

### Debug Features
- **Extension Loading Verification**: Confirms extension is properly installed and recognized
- **Bookmark System Analysis**: Validates bookmark file creation and storage
- **UI Component Testing**: Verifies dialog creation and widget functionality  
- **Error Tracking**: Captures and analyzes extension runtime errors
- **Performance Monitoring**: Tracks memory usage and cleanup operations

## Technical Architecture

### Hash-Based File Association
The extension uses a sophisticated hash algorithm to associate bookmarks with media files:
- **Content-Based**: Uses file content samples (not file path) for identification
- **Relocation Tolerant**: Bookmarks survive file moves and renames
- **Collision Resistant**: 64-bit hash provides strong uniqueness guarantees

### Storage System
- **User Data Directory**: Bookmarks stored in VLC's user data extensions folder
- **JSON-Like Format**: Human-readable Lua table serialization
- **Atomic Updates**: Safe concurrent access and modification
- **Error Recovery**: Graceful handling of corrupted bookmark files

### UI Layout Strategy
Due to VLC's grid layout limitations, the extension uses an "ultra-minimal" approach:
- **Single Column Design**: All elements in column 1 with 1x1 spans
- **Sequential Row Placement**: Avoids complex grid calculations
- **Top-Anchored Positioning**: Ensures proper viewport alignment

## Contributing

This project demonstrates extensive VLC extension development including:
- Advanced debugging methodologies
- Cross-platform deployment automation  
- VLC API limitation workarounds
- Production-ready error handling
- Comprehensive testing frameworks

The debug tools and development workflow can serve as a foundation for other VLC extension projects.

## License

This project is provided as-is for educational and practical use. The original broken source provided inspiration for creating this completely rebuilt implementation.
