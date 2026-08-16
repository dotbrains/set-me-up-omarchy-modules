#!/bin/bash
#
# Installs Raindrop.io via snap: not a pacman/AUR package, so this
# doesn't fit the `packages` DSL. Adapted from
# https://github.com/nicholasadamou/omarchy-scripts/blob/master/raindrop/install.sh
# -- the original re-implemented a full snapd install as a fallback;
# here that's unnecessary because install.sh runs every `packages` file
# (including ../snapd/packages) before any setup.sh, so snapd is already
# present by the time this runs. If it isn't, that's a real problem
# worth surfacing rather than silently re-installing snapd differently
# here than the rest of the module does.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Raindrop.io Installation Script ===${NC}\n"

if ! command -v snap &> /dev/null; then
    echo -e "${RED}Error: snap is not installed.${NC}"
    echo -e "${RED}snapd should have been installed via ../snapd/packages already --${NC}"
    echo -e "${RED}check that install.sh ran the packages files before this script.${NC}"
    exit 1
fi

# Check if Raindrop is already installed
if snap list raindrop &> /dev/null; then
    echo -e "${GREEN}✓ Raindrop.io is already installed${NC}"
    INSTALLED_VERSION=$(snap list raindrop | tail -1 | awk '{print $2}')
    echo -e "Installed version: ${INSTALLED_VERSION}"
else
    # Install Raindrop
    echo -e "${YELLOW}Installing Raindrop.io...${NC}"
    if sudo snap install raindrop; then
        echo -e "${GREEN}✓ Raindrop.io installed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to install Raindrop.io${NC}"
        exit 1
    fi
fi

# Create desktop file symlink for immediate availability in application launcher
SNAP_DESKTOP_FILE="/var/lib/snapd/desktop/applications/raindrop_raindrop.desktop"
USER_DESKTOP_FILE="${HOME}/.local/share/applications/raindrop.desktop"

if [[ -f "$SNAP_DESKTOP_FILE" ]]; then
    echo -e "\n${YELLOW}Creating desktop file symlink...${NC}"
    mkdir -p "${HOME}/.local/share/applications"

    if ln -sf "$SNAP_DESKTOP_FILE" "$USER_DESKTOP_FILE"; then
        echo -e "${GREEN}✓ Desktop file symlink created${NC}"

        if command -v update-desktop-database &> /dev/null; then
            update-desktop-database "${HOME}/.local/share/applications/" 2>/dev/null || true
            echo -e "${GREEN}✓ Desktop database updated${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Could not create desktop file symlink${NC}"
    fi
fi

echo -e "\n${GREEN}=== Installation Complete ===${NC}"
echo -e "Raindrop.io has been installed successfully!"
echo -e "\nYou can launch Raindrop.io from your application menu or by running:"
echo -e "  snap run raindrop"
echo -e "\n${YELLOW}Note:${NC} If the app doesn't appear in your launcher, log out and back in."
