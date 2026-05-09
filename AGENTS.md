# Repository Guidelines

## Project Structure & Module Organization

This repository contains personal NixOS-WSL and Home Manager dotfiles.

- `flake.nix` defines inputs, dev shells, Home Manager outputs, and the `nixos-wsl` system.
- `nixos/configuration.nix` contains WSL system settings such as users, Docker, fonts, and browser automation.
- `home/home.nix` is the main Home Manager module and imports feature modules.
- `home/codex.nix`, `home/tmux.nix`, and `home/nvim.nix` manage Codex CLI, tmux, and Neovim.
- `home/nvim/` contains Lua-based Neovim configuration and plugin specs.
- `docs/` contains workflow notes, currently React Native / Expo guidance.

There is no application source tree or test suite; validation is primarily Nix evaluation.

## Build, Test, and Development Commands

- `nix flake check --all-systems --no-build --show-trace`: evaluate all supported outputs without building everything.
- `nix eval --show-trace '.#homeConfigurations."daiki.miwa".activationPackage.drvPath'`: verify the Linux Home Manager activation package.
- `nix eval --show-trace '.#nixosConfigurations.nixos-wsl.config.system.build.toplevel.drvPath'`: verify the WSL NixOS system derivation.
- `sudo nixos-rebuild switch --flake .#nixos-wsl`: apply the WSL system configuration.
- `home-manager switch --flake .#daiki.miwa-aarch64-darwin`: apply the macOS Home Manager profile.
- `nix develop .#expo -c zsh` and `nix develop .#astro -c zsh`: enter project-specific dev shells.

## Coding Style & Naming Conventions

Format Nix files with `nixfmt-rfc-style` before committing. Keep modules small and purpose-based, for example `home/tmux.nix` for tmux and `home/codex.nix` for Codex. Use two-space indentation in Nix and Lua where practical. Prefer declarative Nix options over activation scripts unless no option exists. Avoid hard-coded user paths; use `username` and `homeDirectory`.

## Testing Guidelines

Run the evaluation commands above after changing `flake.nix`, `home/*.nix`, or `nixos/*.nix`. For Neovim changes, ensure `home/nvim/lazy-lock.json` is updated when plugin versions change. If adding shell helpers, prefer `pkgs.writeShellApplication` so runtime dependencies are explicit.

## Commit & Pull Request Guidelines

Recent commits use short imperative messages, often with a scope, such as `nix: manage WSL and home environment` or `docs: document dev shell workflows`. Keep commits grouped by concern: configuration, editor setup, docs, or cleanup.

Pull requests should include a summary, validation commands run, and notes for any manual post-apply steps such as restarting tmux or re-entering WSL.

When completing a change end-to-end, create a topic branch first, stage the intended files, commit with an imperative message, push the branch, and open a pull request. Start a review agent to review the pull request before merging. If the review agent reports no blocking issues, merge the pull request and clean up the branch as appropriate.

## Security & Configuration Tips

Do not commit secrets, tokens, local Codex state, or machine-specific credentials. Keep `~/.ssh/config.local` outside the repository. `.codex` is ignored intentionally; Codex configuration is generated through Home Manager without storing credentials.
