#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

find . -type f -name '*.sh' -not -path '*/.git/*' -exec bash -n {} +

# hooks/post-update has no .sh extension (Omarchy hooks are plain executables),
# so check it explicitly too.
if [ -f hooks/post-update ]; then
    bash -n hooks/post-update
fi
