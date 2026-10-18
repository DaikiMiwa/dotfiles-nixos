# Repository Guidelines

## Project Structure & Module Organization

This repository contains personal NixOS-WSL and Home Manager dotfiles.

- `flake.nix` defines inputs, dev shells, Home Manager outputs, and the `nixos-wsl` system.
- `nixos/configuration.nix` contains WSL system settings such as users, Docker, fonts, and browser automation.
- `home/home.nix` is the main Home Manager module and imports feature modules.
- `home/opencode.nix`, `home/tmux.nix`, and `home/nvim.nix` manage opencode, tmux, and Neovim.
- `home/nvim/` contains Lua-based Neovim configuration and plugin specs.
- `home/packages/` separates packages by purpose; `home/dotfiles.nix` owns the checkout path and helper commands.
- `docs/` contains workflow notes, currently React Native / Expo guidance.

Validation combines Nix evaluation with formatting, shell checks, and `tests/neovim.lua`.

## Build, Test, and Development Commands

- `nix flake check --all-systems --no-build --show-trace`: evaluate all supported outputs without building everything.
- `nix build --no-link .#checks.aarch64-darwin.format-nix`: execute the format check (use `x86_64-linux` on WSL or `x86_64-darwin` on Intel Mac). `--no-build` only evaluates checks.
- `dotfiles-fmt` and `dotfiles-check`: format Nix/Lua and evaluate all outputs plus execute native checks from any directory. Before applying helpers, follow `docs/operations.md`.
- `nix eval --show-trace '.#homeConfigurations."daiki.miwa".activationPackage.drvPath'`: verify the Linux Home Manager activation package.
- `nix eval --show-trace '.#nixosConfigurations.nixos-wsl.config.system.build.toplevel.drvPath'`: verify the WSL NixOS system derivation.
- `sudo nixos-rebuild switch --flake .#nixos-wsl`: apply the WSL system configuration.
- `home-manager switch --flake .#daiki.miwa-aarch64-darwin`: apply the macOS Home Manager profile.
- `nix develop .#expo -c zsh` and `nix develop .#astro -c zsh`: enter project-specific dev shells.

## Coding Style & Naming Conventions

Format Nix files with `nixfmt-rfc-style` before committing. Keep modules small and purpose-based, for example `home/tmux.nix` for tmux. Use two-space indentation in Nix and Lua where practical. Prefer declarative Nix options over activation scripts unless no option exists. Avoid hard-coded user paths; use `username` and `homeDirectory`.

## Testing Guidelines

Run the evaluation commands above after changing any Nix module and run native checks. For Neovim changes, run `neovim-config` and `format-lua`. lazy.nvim, Treesitter/parsers and LuaSnip are Nix-managed; other plugin revisions live in `home/nvim/lazy-lock.json`. If adding shell helpers, prefer `pkgs.writeShellApplication` so runtime dependencies are explicit.

## Commit & Push Guidelines

Recent commits use short imperative messages, often with a scope, such as `nix: manage WSL and home environment` or `docs: document dev shell workflows`. Keep commits grouped by concern: configuration, editor setup, docs, or cleanup.

This is a personal repository. For routine changes, work directly on `main`: stage only the intended files, commit with an imperative message, run the relevant validation commands, and push `main` to `origin`. Do not create a topic branch, open a pull request, or start a review agent unless explicitly requested.

Before pushing, include a short summary of the change and the validation commands run. Note any manual post-apply steps such as restarting tmux, restarting Herdr, or re-entering WSL.

## Security & Configuration Tips

Do not commit secrets, tokens, local Codex state, or machine-specific credentials. Keep `~/.ssh/config.local` outside the repository. `.codex` is ignored intentionally; local AI CLI configuration and credentials are not managed by this repository.

## Interaction & Communication Guidelines

- ユーザーに対して質問を投げかけた際、ユーザーがその質問に明確に回答しなかった（あるいは別の話題に逸れた）場合は、そのまま作業を進めるのではなく、質問に対する回答をしっかりと追求し、明確な回答を得るようにしてください。
- 長期にわたる、あるいはステップの多い複雑な作業になる場合は、必ず `todo.md` などのアーティファクトを作成・更新し、タスクの進捗状況をユーザーと共有しながら管理してください。
