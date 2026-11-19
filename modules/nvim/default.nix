{ config, lib, pkgs, ... }:
let
  cfg = config.programs.akariNvim;
in {
  options.programs.akariNvim = {
    enable = lib.mkEnableOption "Neovim configuration (lazy.nvim + catppuccin)";
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      withPython3 = true;
      withNodeJs = true;
      withRuby = false;

      # LSP は mason が管理するので、ビルドに必要なものだけ入れる
      extraPackages = with pkgs; [
        git
        gcc
        gnumake
        unzip
        curl
        ripgrep
        fd
        tree-sitter
      ];
    };

    # nvim 設定一式をそのまま配置
    xdg.configFile."nvim".source = ./config;
  };
}
