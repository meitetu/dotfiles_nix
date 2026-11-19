{
  config,
  lib,
  pkgs,
  ...
}:
{

  # --------------------------------------------------------------------------
  # Boot
  # --------------------------------------------------------------------------
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # --------------------------------------------------------------------------
  # Filesystems
  # (インストール時に nixos-generate-config が生成したものに置き換えてください)
  # --------------------------------------------------------------------------
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  # --------------------------------------------------------------------------
  # Networking
  # --------------------------------------------------------------------------
  networking.hostName = "akari";

  # --------------------------------------------------------------------------
  # Locale / timezone
  # --------------------------------------------------------------------------
  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  # --------------------------------------------------------------------------
  # Users
  # --------------------------------------------------------------------------
  users.users.meitetu = {
    isNormalUser = true;
    description = "meitetu";
    extraGroups = [ "networkmanager" "wheel" "video" "render" "input" "audio" ];
    shell = pkgs.zsh;
  };

  # --------------------------------------------------------------------------
  # Nix
  # --------------------------------------------------------------------------
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # --------------------------------------------------------------------------
  # Fonts (CJK + emoji)
  # --------------------------------------------------------------------------
  fonts.fontDir.enable = true;

  # --------------------------------------------------------------------------
  # Hardware acceleration
  # --------------------------------------------------------------------------
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # AMD GPU
  hardware.amdgpu.initrd.enable = lib.mkDefault true;

  # --------------------------------------------------------------------------
  # Akari desktop
  # --------------------------------------------------------------------------
  programs.akari = {
    enable = true;
    # 自分の壁紙に置き換えてください:
    # wallpaper = ../../assets/wallpaper.jpg;
    everydayApps = true;
    faceAuth = true;
    gaming = false;
  };

  # --------------------------------------------------------------------------
  # Misc
  # --------------------------------------------------------------------------
  services.openssh.enable = false;

  system.stateVersion = "25.11";
}
