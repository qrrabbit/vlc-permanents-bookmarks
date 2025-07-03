# VLC Permanent Bookmarks Extension Makefile

.PHONY: install install-user install-system test clean debug review-debug monitor-debug help

# Default target
help:
	@echo "VLC Permanent Bookmarks Extension - Available Commands:"
	@echo ""
	@echo "  make install        - Auto-detect and install extension"
	@echo "  make install-system - Install for all users (requires admin)"
	@echo "  make install-user   - Install for current user only"
	@echo "  make test          - Test if VLC can find the extension"
	@echo "  make debug         - Collect debug information"
	@echo "  make review-debug  - Review collected debug information"
	@echo "  make monitor-debug - Monitor VLC debug output in real-time"
	@echo "  make clean         - Remove extension from user directory"
	@echo "  make help          - Show this help message"
	@echo ""

# Auto-detect and install
install:
	@echo "🚀 Deploying VLC Permanent Bookmarks Extension..."
	@./deploy.sh

# Install for all users (system-wide)
install-system:
	@echo "🔧 Installing extension for all users..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		echo "macOS detected - installing to system directory"; \
		sudo mkdir -p "/Applications/VLC.app/Contents/MacOS/share/lua/extensions"; \
		sudo cp vlc_permanents_bookmarks.lua "/Applications/VLC.app/Contents/MacOS/share/lua/extensions/"; \
		echo "✅ Extension installed system-wide"; \
	elif [ "$$(uname)" = "Linux" ]; then \
		echo "Linux detected - installing to system directory"; \
		sudo mkdir -p "/usr/lib/vlc/lua/extensions"; \
		sudo cp vlc_permanents_bookmarks.lua "/usr/lib/vlc/lua/extensions/"; \
		echo "✅ Extension installed system-wide"; \
	else \
		echo "❌ System installation not supported on this platform"; \
		exit 1; \
	fi

# Install for current user only
install-user:
	@echo "👤 Installing extension for current user..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		echo "macOS detected - installing to user directory"; \
		mkdir -p "$$HOME/Library/Application Support/org.videolan.vlc/lua/extensions"; \
		cp vlc_permanents_bookmarks.lua "$$HOME/Library/Application Support/org.videolan.vlc/lua/extensions/"; \
		echo "✅ Extension installed for current user"; \
	elif [ "$$(uname)" = "Linux" ]; then \
		if [ -d "$$HOME/.local/share/flatpak/app/org.videolan.VLC" ]; then \
			echo "Flatpak VLC detected"; \
			mkdir -p "$$HOME/.local/share/flatpak/app/org.videolan.VLC/x86_64/stable/active/files/lib/vlc/lua/extensions"; \
			cp vlc_permanents_bookmarks.lua "$$HOME/.local/share/flatpak/app/org.videolan.VLC/x86_64/stable/active/files/lib/vlc/lua/extensions/"; \
		else \
			echo "Regular VLC detected"; \
			mkdir -p "$$HOME/.local/share/vlc/lua/extensions"; \
			cp vlc_permanents_bookmarks.lua "$$HOME/.local/share/vlc/lua/extensions/"; \
		fi; \
		echo "✅ Extension installed for current user"; \
	else \
		echo "❌ User installation not implemented for this platform"; \
		exit 1; \
	fi

# Test if extension is accessible
test:
	@echo "🧪 Testing extension accessibility..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		if [ -f "/Applications/VLC.app/Contents/MacOS/share/lua/extensions/vlc_permanents_bookmarks.lua" ]; then \
			echo "✅ Extension found in system directory"; \
		elif [ -f "$$HOME/Library/Application Support/org.videolan.vlc/lua/extensions/vlc_permanents_bookmarks.lua" ]; then \
			echo "✅ Extension found in user directory"; \
		else \
			echo "❌ Extension not found in any expected location"; \
			exit 1; \
		fi \
	elif [ "$$(uname)" = "Linux" ]; then \
		if [ -f "/usr/lib/vlc/lua/extensions/vlc_permanents_bookmarks.lua" ]; then \
			echo "✅ Extension found in system directory"; \
		elif [ -f "$$HOME/.local/share/vlc/lua/extensions/vlc_permanents_bookmarks.lua" ]; then \
			echo "✅ Extension found in user directory"; \
		elif [ -f "$$HOME/.local/share/flatpak/app/org.videolan.VLC/x86_64/stable/active/files/lib/vlc/lua/extensions/vlc_permanents_bookmarks.lua" ]; then \
			echo "✅ Extension found in Flatpak directory"; \
		else \
			echo "❌ Extension not found in any expected location"; \
			exit 1; \
		fi \
	fi

# Clean up user installation
clean:
	@echo "🧹 Removing extension from user directories..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		rm -f "$$HOME/Library/Application Support/org.videolan.vlc/lua/extensions/vlc_permanents_bookmarks.lua"; \
		echo "✅ Extension removed from user directory"; \
	elif [ "$$(uname)" = "Linux" ]; then \
		rm -f "$$HOME/.local/share/vlc/lua/extensions/vlc_permanents_bookmarks.lua"; \
		rm -f "$$HOME/.local/share/flatpak/app/org.videolan.VLC/x86_64/stable/active/files/lib/vlc/lua/extensions/vlc_permanents_bookmarks.lua"; \
		echo "✅ Extension removed from user directories"; \
	fi

# Collect debug information
debug:
	@echo "🔍 Collecting debug information..."
	@./debug_vlc.sh

# Review collected debug information
review-debug:
	@echo "📋 Reviewing debug information..."
	@./review_debug.sh

# Monitor VLC debug output in real-time
monitor-debug:
	@echo "🔍 Monitoring VLC debug output in real-time..."
	@./monitor_debug.sh 