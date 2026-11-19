{ config, lib, pkgs, ... }:
let
  cfg = config.programs.akariStarship;
in {
  options.programs.akariStarship = {
    enable = lib.mkEnableOption "Starship prompt theme";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      settings = lib.mkDefault (builtins.fromTOML (builtins.readFile ./starship.toml));
    };
  };
}
