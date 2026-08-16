#!/bin/bash
#
# Installs Warp Terminal via its AppImage: not a pacman/AUR package, so
# this doesn't fit the `packages` DSL -- it downloads the AppImage,
# extracts an icon, and writes a .desktop entry. Ported from
# https://github.com/nicholasadamou/omarchy-scripts/blob/master/warp/install.sh
# (idempotent: safe to re-run, checks for updates on subsequent runs).

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
WARP_URL="https://releases.warp.dev/stable/latest/linux"
INSTALL_DIR="/opt"
APPIMAGE_PATH="${INSTALL_DIR}/warp.appimage"
DESKTOP_ENTRY="${HOME}/.local/share/applications/warp.desktop"
ICON_DIR="${HOME}/.local/share/icons"
ICON_PATH="${ICON_DIR}/warp.png"

echo -e "${GREEN}=== Warp Terminal Installation Script ===${NC}\n"

# Check if running on Linux
if [[ "$(uname)" != "Linux" ]]; then
    echo -e "${RED}Error: This script is designed for Linux only.${NC}"
    exit 1
fi

# Check for required commands
for cmd in curl file; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is required but not installed.${NC}"
        exit 1
    fi
done

# Check if Warp is already installed
if [[ ! -f "$APPIMAGE_PATH" ]]; then
    # Download Warp AppImage
    echo -e "${YELLOW}Downloading Warp Terminal...${NC}"
    TMP_APPIMAGE=$(mktemp)
    if curl -L -o "$TMP_APPIMAGE" "$WARP_URL"; then
        echo -e "${GREEN}✓ Download complete${NC}"
    else
        echo -e "${RED}✗ Failed to download Warp${NC}"
        rm -f "$TMP_APPIMAGE"
        exit 1
    fi

    # Move to install directory (requires sudo if /opt)
    echo -e "${YELLOW}Installing to ${APPIMAGE_PATH}...${NC}"
    if [[ -w "$INSTALL_DIR" ]]; then
        mv "$TMP_APPIMAGE" "$APPIMAGE_PATH"
        chmod +x "$APPIMAGE_PATH"
    else
        sudo mv "$TMP_APPIMAGE" "$APPIMAGE_PATH"
        sudo chmod +x "$APPIMAGE_PATH"
    fi
    echo -e "${GREEN}✓ Installed to ${APPIMAGE_PATH}${NC}"
else
    echo -e "${YELLOW}Warp is already installed at ${APPIMAGE_PATH}${NC}"
    echo -e "${YELLOW}Checking for updates...${NC}"

    # Download new version to compare
    TMP_APPIMAGE=$(mktemp)
    if curl -L -o "$TMP_APPIMAGE" "$WARP_URL"; then
        # Compare file sizes as a simple update check
        OLD_SIZE=$(stat -c%s "$APPIMAGE_PATH" 2>/dev/null || stat -f%z "$APPIMAGE_PATH" 2>/dev/null)
        NEW_SIZE=$(stat -c%s "$TMP_APPIMAGE" 2>/dev/null || stat -f%z "$TMP_APPIMAGE" 2>/dev/null)

        if [[ "$OLD_SIZE" == "$NEW_SIZE" ]]; then
            echo -e "${GREEN}✓ Warp is up to date${NC}"
            rm -f "$TMP_APPIMAGE"
        else
            echo -e "${YELLOW}Update available, installing...${NC}"
            if [[ -w "$INSTALL_DIR" ]]; then
                mv "$TMP_APPIMAGE" "$APPIMAGE_PATH"
                chmod +x "$APPIMAGE_PATH"
            else
                sudo mv "$TMP_APPIMAGE" "$APPIMAGE_PATH"
                sudo chmod +x "$APPIMAGE_PATH"
            fi
            echo -e "${GREEN}✓ Updated to latest version${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Could not check for updates, keeping existing installation${NC}"
        rm -f "$TMP_APPIMAGE"
    fi
fi

# Extract icon from AppImage (only if not already present)
if [[ ! -f "$ICON_PATH" ]]; then
    echo -e "${YELLOW}Extracting icon...${NC}"
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    "$APPIMAGE_PATH" --appimage-extract >/dev/null 2>&1

    # Find the highest resolution icon
    ICON_FILE=$(find squashfs-root -name "*.png" | grep -i "warp" | grep "256x256" | head -1)
    [[ -z "$ICON_FILE" ]] && ICON_FILE=$(find squashfs-root -name "*.png" | grep -i "warp" | head -1)

    if [[ -n "$ICON_FILE" ]]; then
        mkdir -p "$ICON_DIR"
        cp "$ICON_FILE" "$ICON_PATH"
        echo -e "${GREEN}✓ Icon extracted to ${ICON_PATH}${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Could not find icon in AppImage${NC}"
    fi

    # Clean up extraction
    cd - >/dev/null
    rm -rf "$TMP_DIR"
else
    echo -e "${GREEN}✓ Icon already exists at ${ICON_PATH}${NC}"
fi

# Create desktop entry (only if not already present or needs update)
if [[ ! -f "$DESKTOP_ENTRY" ]] || ! grep -q "Exec=${APPIMAGE_PATH}" "$DESKTOP_ENTRY" 2>/dev/null; then
    echo -e "${YELLOW}Creating desktop entry...${NC}"
    mkdir -p "$(dirname "$DESKTOP_ENTRY")"
    cat > "$DESKTOP_ENTRY" << EOF
[Desktop Entry]
Name=Warp
Exec=${APPIMAGE_PATH}
Icon=${ICON_PATH}
Type=Application
Categories=Development;System;TerminalEmulator;
Terminal=false
Comment=Warp Terminal - The terminal for the 21st century
EOF
    echo -e "${GREEN}✓ Desktop entry created at ${DESKTOP_ENTRY}${NC}"
else
    echo -e "${GREEN}✓ Desktop entry already exists at ${DESKTOP_ENTRY}${NC}"
fi

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$(dirname "$DESKTOP_ENTRY")" 2>/dev/null || true
    echo -e "${GREEN}✓ Desktop database updated${NC}"
fi

echo -e "\n${GREEN}=== Installation Complete ===${NC}"
echo -e "Warp Terminal has been installed successfully!"
echo -e "You can launch it from your application menu or run: ${APPIMAGE_PATH}"
