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
      environment = {
        systemPackages = with pkgs; [bird2 arouteserver];
        etc = {
          "arouteserver/general.yml".source = format.generate "general.yml" cfg.generalConfig;
          "arouteserver/clients.yml".source = format.generate "clients.yml" cfg.clientsConfig;
        };
      };

      systemd.services = {
        arouteserver-setup = {
          wantedBy = [
            "arouteserver.service"
          ];
          serviceConfig = {
            ReadWritePaths = [
              "/etc/arouteserver"
            ];
            Group = "bird";
            Type = "oneshot";
            Restart = "on-failure";
            ExecPaths = ["/nix/store"];
            NoExecPaths = ["/"];
          };
          path = with pkgs; [bgpq4 arouteserver];
          script = ''
            mkdir -p /etc/arouteserver
            yes no | arouteserver setup --dest-dir /etc/arouteserver
          '';
        };
        arouteserver = {
          description = "A route server config generator";
          reloadTriggers = [
            config.environment.etc."arouteserver/general.yml".source
            config.environment.etc."arouteserver/clients.yml".source
          ];
          wantedBy = [
            "bird.service"
          ];
          path = with pkgs; [bgpq4];
          serviceConfig = {
            Group = "bird";
            Type = "forking"; # ARS stays attached to console while it generates; Type="forking" means it will fail if ARS fails
            ExecStart = "${getExe pkgs.arouteserver} bird --target-version 2.16 -o /etc/arouteserver/bird.conf";
            ExecReload = "${getExe pkgs.arouteserver} bird --target-version 2.16 -o /etc/arouteserver/bird.conf";
            RuntimeDirectory = "arouteserver";
            TimeoutStartSec = 120; # Two minute delay to ensure it doesn't time out
          };
          startAt = "daily";
        };
        bird = let
          caps = [
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
            "CAP_NET_RAW"
          ];
          pkg = pkgs.bird2;
        in {
          description = "BIRD Internet Routing Daemon";
          wantedBy = ["multi-user.target"];
          reloadTriggers = [
            "/etc/bird/bird.conf"
            config.environment.etc."arouteserver/general.yml".source
            config.environment.etc."arouteserver/clients.yml".source
          ];
          serviceConfig = {
            Type = "forking";
            Restart = "on-failure";
            User = "bird";
            Group = "bird";
            ExecStart = "${lib.getExe' pkg "bird"} -c /etc/arouteserver/bird.conf";
            ExecReload = "${lib.getExe' pkg "birdc"} configure";
            ExecStop = "${lib.getExe' pkg "birdc"} down";
            RuntimeDirectory = "bird";
            ReadWritePaths = [
              "/var/log"
            ];
            CapabilityBoundingSet = caps;
            AmbientCapabilities = caps;
            ProtectSystem = "full";
            ProtectHome = "yes";
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            PrivateTmp = true;
            PrivateDevices = true;
            SystemCallFilter = "~@cpu-emulation @debug @keyring @module @mount @obsolete @raw-io";
            MemoryDenyWriteExecute = "yes";
          };
        };
      };
      users = {
        users.bird = {
          description = "BIRD Internet Routing Daemon user";
          group = "bird";
          isSystemUser = true;
        };
        groups.bird = {};
      };

      # Increase netlink buffers to stop bird from overflowing the netlink socket queue
      boot.kernel.sysctl = {
        "net.core.rmem_default" = 4194304;
        "net.core.rmem_max" = 4194304;
      };
    };
}
