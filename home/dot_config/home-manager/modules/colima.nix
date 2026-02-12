{ config, lib, pkgs, ... }:

let
  cfg = config.programs.colima;
in
{
  options.programs.colima = {
    enable = lib.mkEnableOption "colima";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.colima;
      description = "colima package to install when enabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
