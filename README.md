# 'set-me-up' Omarchy Modules

[![Lint](https://github.com/dotbrains/set-me-up-omarchy-modules/actions/workflows/lint.yml/badge.svg)](https://github.com/dotbrains/set-me-up-omarchy-modules/actions/workflows/lint.yml)
[![License: PolyForm Shield 1.0.0](https://img.shields.io/badge/License-PolyForm%20Shield%201.0.0-blue.svg)](https://polyformproject.org/licenses/shield/1.0.0)

This repository contains [Omarchy](https://github.com/basecamp/omarchy)
modules for the [`set-me-up`](https://github.com/dotbrains/set-me-up)
project.

⚠️ **Note**: This repository should not be used as a standalone script
because it has a dependency on an existing `set-me-up` configuration already
installed on your machine.

## Requirements

- [Omarchy](https://github.com/basecamp/omarchy) — DHH's opinionated Arch
  Linux + Hyprland desktop distro. These modules only run on Omarchy systems
  (detected via `is_omarchy`, which checks for `/usr/share/omarchy`).
- An existing `set-me-up` installation.

## What this module does

`install.sh` at the repo root is the single entry point: it verifies the
host is running Omarchy, then walks this repository for every file named
`packages` and installs it via
[`dotbrains/utilities`](https://github.com/dotbrains/utilities)'s existing
pacman/AUR installer (`pacman::pacman_install_from_file`, aliased as
`pacman_install_from_file`). It deliberately does **not** shell out to
Omarchy's own `omarchy-pkg-add` / `omarchy-pkg-aur-add` commands — those are
themselves thin wrappers over `pacman -S --noconfirm --needed` and
`yay -S --noconfirm --needed` respectively, so reusing the installer this
ecosystem already ships keeps package installation consistent across every
Arch-based module rather than depending on Omarchy-specific tooling for
something that isn't actually Omarchy-specific.

## The `packages` file format

Each `packages` file is a small DSL parsed by `pacman_install_from_file`:

```text
pacman "package-name"                  # install from the official repos
aur "package-name"                     # install from the AUR (default helper: yay)
aur "package-name" [helper: "yay"]     # install from the AUR with an explicit helper
remove "package-name"                  # remove a package (via pacman -Rns)
```

Lines starting with `#` are comments and are ignored.

This repo ships no curated `packages` file — see
[`packages.example`](packages.example) for a comment-only scaffold showing
the format. Copy it to a `packages` file (no extension) wherever you want
one and fill in the packages you actually want on your own hardware; nothing
is installed by default.

## The Omarchy integration: the `post-update` hook

Omarchy fires hooks at a handful of system events, including `post-update`
during `omarchy update`, after packages and migrations have run (see the
["Running scripts on system events"](https://github.com/basecamp/omarchy/blob/master/manual/31-dotfiles.md)
section of the Omarchy manual). Every executable file dropped into
`~/.config/omarchy/hooks/<event>.d/` runs when that event fires.

[`hooks/post-update`](hooks/post-update) is the genuinely Omarchy-specific
piece of this module: it runs `smu update` if the `smu` command is on
`PATH`, keeping your `set-me-up` dotfiles in sync every time `omarchy
update` runs. It no-ops cleanly (exit 0) if `smu` isn't installed.

Install it with Omarchy's own hook-install command:

```bash
omarchy hook install post-update <path-to-this-repo>/hooks/post-update
```

## Usage

This module is designed to be used as a submodule within the
[`set-me-up` blueprint](https://github.com/dotbrains/set-me-up-blueprint)
repository. It is automatically executed when included in your `set-me-up`
configuration; the main script `install.sh` handles package installation,
and `hooks/post-update` is installed separately (once) via `omarchy hook
install` as shown above.

## Validation

`scripts/validate.sh` runs `bash -n` over every shell script in this repo
(including the extensionless `hooks/post-update`) and exits nonzero on any
failure. It's the "native validator" the `set-me-up` coordinator repo looks
for when auditing module repos.

## _Why abstract these modules to an external repository?_

Please see the
[universal modules documentation](https://github.com/dotbrains/set-me-up-universal-modules#why-abstract-these-modules-to-an-external-repository)
for more details on this point.

## License

Licensed under [PolyForm Shield 1.0.0][license].
See [LICENSE](LICENSE) for details.

[license]: https://polyformproject.org/licenses/shield/1.0.0
