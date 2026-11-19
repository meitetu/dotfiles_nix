{ config, pkgs, inputs, ... }:
{
  home.username = "meitetu";
  home.homeDirectory = "/home/meitetu";
  home.stateVersion = "25.11";

  # Akari テーマ（Hyprland + Quickshell）
  programs.akari = {
    enable = true;
    enableHyprland = true;
    # wallpaper = ../../assets/wallpaper.jpg;
  };

  # シェル
  programs.akariShell.enable = true;

  # プロンプト
  programs.akariStarship.enable = true;

  # エディタ
  programs.akariNvim.enable = true;

  # --------------------------------------------------------------------------
  # Git
  # --------------------------------------------------------------------------
  programs.git = {
    enable = true;
    settings = {
      user.name = "meitetu";
      user.email = "meitetu@example.com";
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  # --------------------------------------------------------------------------
  # Common home packages
  # --------------------------------------------------------------------------
  home.packages = with pkgs; [
    ripgrep
    tree
    wget
    curl
    unzip
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
