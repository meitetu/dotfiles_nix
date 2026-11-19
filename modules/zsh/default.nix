{ config, lib, pkgs, ... }:
let
  cfg = config.programs.akariShell;
in {
  options.programs.akariShell = {
    enable = lib.mkEnableOption "zsh configuration (sheldon + starship)";
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = false; # sheldon が管理
      autocd = true;
      dotDir = "${config.xdg.configHome}/zsh";

      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        share = true;
      };

      shellAliases = {
        ls = "eza --icons";
        ll = "eza -la --icons";
        la = "eza -a --icons";
        cat = "bat";
        tree = "eza --tree --icons";
      };

      initContent = lib.mkBefore ''
        # --- sheldon: zsh プラグイン管理 -------------------------------------
        eval "$(sheldon source)"

        # --- starship: プロンプト ---------------------------------------------
        eval "$(starship init zsh)"
      '';
    };

    home.packages = with pkgs; [
      sheldon
      starship
      zoxide
      fzf
      eza
      bat
      fd
      ripgrep
    ];

    # sheldon のプラグイン定義
    xdg.configFile."sheldon/plugins.toml".source = ./plugins.toml;

  };
}
