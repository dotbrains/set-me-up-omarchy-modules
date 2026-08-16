#!/bin/bash

# shellcheck source=/dev/null

declare current_dir &&
    current_dir="$(dirname "${BASH_SOURCE[0]}")" &&
    cd "${current_dir}" &&
    source "$HOME/set-me-up/dotfiles/utilities/import.sh"

smu::import base
smu::import system
smu::import pacman

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    if ! is_omarchy; then
        error "These modules are only for Omarchy systems!"
        return 1
    fi

    ask_for_sudo

    while IFS= read -r -d '' packages_file; do
        (
            cd "$(dirname "$packages_file")" &&
                pacman_install_from_file "$(basename "$packages_file")"
        )
    done < <(find . -type f -name "packages" -print0)

}

main
