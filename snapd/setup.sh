#!/bin/bash
#
# Post-install configuration for snapd: not something the pacman/AUR
# `packages` DSL can express, so it runs here as a setup.sh once
# ../snapd/packages has installed the snapd package itself. Adapted
# from the systemctl/symlink steps in
# https://github.com/nicholasadamou/omarchy-scripts/blob/master/snapd/install.sh
# (the AUR build steps there are dropped -- packages already handled
# that).

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== snapd Setup ===${NC}\n"

if ! command -v snap &> /dev/null; then
    echo -e "${RED}Error: snap is not installed.${NC}"
    echo -e "${RED}snapd should have been installed via ../snapd/packages already --${NC}"
    echo -e "${RED}check that install.sh ran the packages files before this script.${NC}"
    exit 1
fi

# Enable snapd socket
echo -e "${YELLOW}Enabling snapd socket...${NC}"
if sudo systemctl enable --now snapd.socket; then
    echo -e "${GREEN}✓ snapd socket enabled${NC}"
else
    echo -e "${YELLOW}⚠ Could not enable snapd socket (may already be enabled)${NC}"
fi

# Check if AppArmor is enabled
if ! systemctl is-active --quiet apparmor 2>/dev/null; then
    echo -e "${GREEN}✓ AppArmor not detected, skipping snapd.apparmor.service${NC}"
else
    echo -e "${YELLOW}AppArmor detected, enabling snapd.apparmor.service...${NC}"
    if sudo systemctl enable --now snapd.apparmor.service; then
        echo -e "${GREEN}✓ snapd.apparmor.service enabled${NC}"
    else
        echo -e "${YELLOW}⚠ Could not enable snapd.apparmor.service${NC}"
    fi
fi

# Enable classic snap support
if [[ ! -L /snap ]]; then
    echo -e "${YELLOW}Creating symbolic link for classic snap support...${NC}"
    if sudo ln -s /var/lib/snapd/snap /snap; then
        echo -e "${GREEN}✓ Classic snap support enabled${NC}"
    else
        echo -e "${YELLOW}⚠ Could not create /snap symlink (may already exist)${NC}"
    fi
else
    echo -e "${GREEN}✓ Classic snap support already enabled${NC}"
fi

echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo -e "snapd has been configured successfully!"
echo -e "\n${YELLOW}IMPORTANT:${NC} You need to log out and log back in (or restart your system)"
echo -e "to ensure snap's paths are updated correctly.\n"
