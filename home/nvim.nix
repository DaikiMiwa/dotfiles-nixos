{ config, pkgs, ... }:

let
  lazyNvim = pkgs.vimPlugins.lazy-nvim.overrideAttrs (old: {
    # Local Nix plugins already contain helptags and cannot be written by :Lazy restore.
    postPatch = (old.postPatch or "") + ''
      substituteInPlace lua/lazy/manage/task/plugin.lua \
        --replace-fail 'return not plugin._.is_local and not plugin._.dirty' \
        'return vim.fn.filewritable(plugin.dir .. "/doc") ~= 2 or (not plugin._.is_local and not plugin._.dirty)'
    '';
  });
  treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
    p: with p; [
      astro
      bash
      bibtex
      c
      css
      diff
      html
      javascript
      jsdoc
      json
      jsonc
      latex
      lua
      luadoc
      luap
      markdown
      markdown_inline
      nix
      scss
      printf
      python
      query
      regex
      toml
      tsx
      typescript
      vim
      vimdoc
      xml
      yaml
    ]
  );
in
{
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.repository}/home/nvim";

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = [
      lazyNvim
      treesitter
      pkgs.vimPlugins.luasnip
    ];
    extraPackages = [
      pkgs.gcc
      pkgs.gnumake
      pkgs.nodejs_22
    ];
    extraWrapperArgs = [
      "--set"
      "NVIM_LAZY_PATH"
      "${lazyNvim}"
      "--set"
      "NVIM_TREESITTER_PATH"
      "${treesitter}"
      "--set"
      "NVIM_LUASNIP_PATH"
      "${pkgs.vimPlugins.luasnip}"
    ];
  };
}
