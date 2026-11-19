{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.akari;
in {
  options.programs.akari = {
    enable = lib.mkEnableOption "Akari Hoshizaki desktop environment";

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Wallpaper image. Exposed at /etc/akari/wallpaper.jpg so it can be
        linked into ~/.local/share/wallpapers/akari.jpg.
      '';
    };

    everydayApps = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install everyday applications (browser, file manager, media
        players, editor, ...).
      '';
    };

    faceAuth = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Face authentication via Gaze (gazed + pam_gaze). Wires face auth into
        sudo, polkit and hyprlock with the password as a fallback.
        Enroll with `gaze add-face default` after the first rebuild.
      '';
    };

    gaming = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install gaming extras (Steam, PrismLauncher, protonup-qt).
        Steam is unfree; this also allows it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # ------------------------------------------------------------------------
    # Compositor
    # ------------------------------------------------------------------------
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    programs.hyprlock.enable = true;

    # ------------------------------------------------------------------------
    # System services
    # ------------------------------------------------------------------------
    services = {
      displayManager.gdm.enable = lib.mkDefault true;

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      gnome.gnome-keyring.enable = true;
      upower.enable = true;
    };

    networking.networkmanager.enable = true;

    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      config.common.default = [ "hyprland" "gtk" ];
    };

    # ------------------------------------------------------------------------
    # Japanese input (fcitx5 + Mozc)
    # ------------------------------------------------------------------------
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
        qt6Packages.fcitx5-configtool
        qt6Packages.fcitx5-qt
      ];
    };

    # ------------------------------------------------------------------------
    # Fonts
    # ------------------------------------------------------------------------
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        material-symbols
        noto-fonts
        dejavu_fonts
        liberation_ttf
      ];
      fontDir.enable = true;
      fontconfig.defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" "Noto Sans Mono CJK JP" ];
        sansSerif = [ "Noto Sans" "Noto Sans CJK JP" ];
        serif = [ "Noto Serif" "Noto Serif CJK JP" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    # ------------------------------------------------------------------------
    # Face authentication (Gaze)
    # ------------------------------------------------------------------------
    services.gaze = lib.mkIf cfg.faceAuth {
      enable = true;
      gui.enable = true;
      pam.defaultServices = [ "sudo" "polkit-1" "hyprlock" ];
    };

    security.pam.services.hyprlock.gaze = lib.mkIf cfg.faceAuth {
      enable = true;
      simultaneous = true;
    };

    # ------------------------------------------------------------------------
    # Packages
    # ------------------------------------------------------------------------
    environment.systemPackages = with pkgs;
      [
        # --- Compositor / shell ------------------------------------------
        hyprland
        quickshell
        kitty
        awww
        swaybg

        # --- Session helpers ---------------------------------------------
        hypridle
        hyprsunset
        kdePackages.polkit-kde-agent-1
        networkmanagerapplet
        pavucontrol
        playerctl
        brightnessctl
        wireplumber
        libnotify

        # --- Clipboard / screenshots -------------------------------------
        wl-clipboard
        cliphist
        wl-clip-persist
        grim
        slurp
        wf-recorder
        satty

        # --- Utilities ---------------------------------------------------
        jq
        python3
        wofi
        fd
        bat
        htop
        btop
        fastfetch
        ncdu
        smartmontools
        wlr-randr
        xdg-utils
        file-roller
        p7zip

        # --- Shell / editor ----------------------------------------------
        zsh
        starship
        sheldon
        neovim
        git
        tmux
        fzf
        zoxide
        direnv
        lazygit
        shellcheck
        gh

        # --- Gaming (free part) ------------------------------------------
        gamemode
        gamescope
        mangohud
      ]
      ++ lib.optionals cfg.everydayApps (with pkgs; [
        firefox
        mpv
        imv
        vlc
        telegram-desktop
        vesktop
        obs-studio
        qbittorrent
        remmina

        # --- KDE applications -------------------------------------------
        kdePackages.dolphin
        kdePackages.kate
        kdePackages.ark
        kdePackages.spectacle
        kdePackages.ksshaskpass
        kdePackages.filelight
        kdePackages.gwenview
        kdePackages.okular
        kdePackages.kwalletmanager
        kdePackages.kscreen
        kdePackages.print-manager
      ])
      ++ lib.optionals cfg.gaming (with pkgs; [
        steam
        prismlauncher
        protonup-qt
      ]);

    # Steam is unfree
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [ "steam" "steam-unwrapped" ];

    # ------------------------------------------------------------------------
    # Wallpaper
    # ------------------------------------------------------------------------
    environment.etc = lib.mkIf (cfg.wallpaper != null) {
      "akari/wallpaper.jpg".source = cfg.wallpaper;
    };

    # ------------------------------------------------------------------------
    # Session environment
    # ------------------------------------------------------------------------
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      LIBVA_DRIVER_NAME = lib.mkDefault "radeonsi";
    };

    programs.zsh.enable = true;
  };
}
