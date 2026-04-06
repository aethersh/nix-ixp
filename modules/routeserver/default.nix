{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.vtix.routeserver;

  format = pkgs.formats.yaml {};
in {
  options.vtix.routeserver = with lib; {
    enable = mkEnableOption "Enable automatic route servers for Vermont IX";
    generalConfig = mkOption {
      description = "Arouteserver Generic YAML Configuration";
      type = types.submodule {
        freeformType = format.type;
      };
    };
    clientsConfig = mkOption {
      description = "Arouteserver Clients YAML Configuration";
      type = types.submodule {
        freeformType = format.type;
      };
    };
  };

  config = with lib;
    mkIf cfg.enable {
      # environment.etc."bird/constants.conf".source = ./bird/constants.conf;
      # environment.etc."bird/base.conf".source = ./bird/base.conf;
      environment.etc = {
        "arouteserver/general.yml".source = format.generate "general.yml" cfg.generalConfig;
        "arouteserver/clients.yml".source = format.generate "clients.yml" cfg.clientsConfig;
      };

      services.bird = {
        enable = true;
        package = pkgs.bird2;
        checkConfig = false;
      };

      systemd.services.bird.reloadTriggers = [
        config.environment.etc."arouteserver/general.yml".source
        config.environment.etc."arouteserver/clients.yml".source
      ];

      systemd.services = {
        arouteserver = {
          description = "A route server config generator";
          wantedBy = ["multi-user.target"];
          reloadTriggers = [
            config.environment.etc."arouteserver/general.yml".source
            config.environment.etc."arouteserver/clients.yml".source
          ];
          requiredBy = [
            "bird.service"
          ];
          path = with pkgs; [bgpq4];
          serviceConfig = {
            Type = "forking"; # ARS stays attached to console while it generates; Type="forking" means it will fail if ARS fails
            ExecStart = "${getExe pkgs.arouteserver} bird -o /etc/bird/bird.conf";
            ExecReload = "${getExe pkgs.arouteserver} bird -o /etc/bird/bird.conf";
            RuntimeDirectory = "arouteserver";
            TimeoutStartSec = 120; # Two minute delay to ensure it doesn't time out
          };
          startAt = "daily";
        };
      };

      # Increase netlink buffers to stop bird from overflowing the netlink socket queue
      boot.kernel.sysctl = {
        "net.core.rmem_default" = 4194304;
        "net.core.rmem_max" = 4194304;
      };
    };
}
