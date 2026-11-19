{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.akari;
  src = ../../modules/akari;
in {
  options.programs.akari = {
    enable = lib.mkEnableOption "Akari Hoshizaki desktop theme (home-manager)";

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Wallpaper installed to ~/.local/share/wallpapers/akari.jpg.";
    };

    enableHyprland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Deploy the Akari Hyprland configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    # --- Scripts ----------------------------------------------------------
    home.packages = with pkgs; [
      jq
      python3
      grim
      slurp
      wl-clipboard
      cliphist
      brightnessctl
      playerctl
      libnotify
      wofi
      quickshell
      kitty
    ];

    home.file = lib.mkMerge [
      (lib.mkIf cfg.enableHyprland {
        ".config/hypr/hyprland.lua".source = "${src}/config/hypr/hyprland.lua";
        ".config/hypr/modules".source = "${src}/config/hypr/modules";
        ".config/hypr/hyprlock.conf".source = "${src}/config/hypr/hyprlock.conf";
        ".config/hypr/hypridle.conf".source = "${src}/config/hypr/hypridle.conf";
      })
    ];

    # --- Theme files ------------------------------------------------------
    xdg.configFile = {
      "quickshell/akari".source = "${src}/config/quickshell/akari";
      "wofi/config".source = "${src}/config/wofi/config";
      "wofi/style.css".source = "${src}/config/wofi/style.css";
      "kitty/kitty.conf".source = "${src}/config/kitty/kitty.conf";
      "kitty/tab_bar.py".source = "${src}/config/kitty/tab_bar.py";
      "cava/config".source = "${src}/config/cava/config";
      "btop/btop.conf".source = "${src}/config/btop/btop.conf";
      "btop/themes/akari-star.theme".source = "${src}/config/btop/themes/akari-star.theme";
      "fastfetch/config.jsonc".source = "${src}/config/fastfetch/config.jsonc";
      "fastfetch/akari-star.txt".source = "${src}/config/fastfetch/akari-star.txt";
      "fontconfig/fonts.conf".source = "${src}/config/fontconfig/fonts.conf";
      "fcitx5/conf/classicui.conf".source = "${src}/config/fcitx5/conf/classicui.conf";
    };

    xdg.dataFile = lib.mkMerge [
      {
        "fcitx5/themes/akari-star".source =
          "${src}/local-share/fcitx5/themes/akari-star";
      }
      (lib.mkIf (cfg.wallpaper != null) {
        "wallpapers/akari.jpg".source = cfg.wallpaper;
      })
    ];
  };
}
