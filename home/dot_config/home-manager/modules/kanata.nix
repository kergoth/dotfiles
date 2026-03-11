{ config, lib, pkgs, ... }:

let
  progCfg = config.programs.kanata;
  svcCfg = config.services.kanata;
in
{
  options.programs.kanata = {
    enable = lib.mkEnableOption "kanata";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.kanata;
      description = "kanata package to install when enabled.";
    };
  };

  options.services.kanata = {
    enable = lib.mkEnableOption "kanata user service";

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/kanata/kanata.kbd";
      description = "Path to the kanata configuration file.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (progCfg.enable || svcCfg.enable) {
      home.packages = [ progCfg.package ];
    })

    (lib.mkIf svcCfg.enable {
      systemd.user.services.kanata = {
        Unit = {
          Description = "Kanata keyboard remapper";
          After = [ "graphical-session.target" ];
          ConditionPathExists = svcCfg.configPath;
        };
        Service = {
          ExecStart = "${progCfg.package}/bin/kanata --cfg ${svcCfg.configPath}";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    })
  ];
}
