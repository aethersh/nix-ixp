{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.vtix.routeserver;

  format = pkgs.formats.yaml {};

  rs4Socket = "/var/run/bird4/bird4.ctl";
  rs6Socket = "/var/run/bird6/bird6.ctl";

  rs4Config = "/var/lib/bird/bird-v4.conf";
  rs6Config = "/var/lib/bird/bird-v6.conf";
in {
  options.vtix.routeserver = with lib; {
    enable = mkEnableOption "Enable automatic route servers for Vermont IX";
    ixpManager = {
      baseUrl = mkOption {
        description = "";
        type = types.str;
        default = "http://ixpm.sbtnvt.vermont-ix.net";
      };
      apiKey = mkOption {
        description = "";
        type = types.str;
      };
      rs4Handle = mkOption {
        description = "";
        type = types.str;
      };
      rs6Handle = mkOption {
        description = "";
        type = types.str;
      };
    };

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
    mkIf cfg.enable (let
      birdPkg = pkgs.bird2;
      birdc4 = "${birdPkg}/bin/birdc -s ${rs4Socket}";
      birdc6 = "${birdPkg}/bin/birdc -s ${rs6Socket}";

      ixpmScriptGenerator = let
        ixpmUrlLock = "${cfg.ixpManager.baseUrl}/api/v4/router/get-update-lock";
        ixpmUrlConfig = "${cfg.ixpManager.baseUrl}/api/v4/router/gen-config";
        ixpmUrlLockRelease = "${cfg.ixpManager.baseUrl}/api/v4/router/release-update-lock";
        ixpmUrlUpdated = "${cfg.ixpManager.baseUrl}/api/v4/router/updated";
      in
        handle: confPath: socketPath: ''
          echo "Script started"

          if [[ -e ${confPath} ]]; then
            rm -f ${confPath}.old
            cp -f ${confPath} ${confPath}.old
            echo "Backed up old config to ${confPath}.old"
            echo "##########################################################"
          fi

          rm -f ${confPath}.new
          ${pkgs.curl}/bin/curl --verbose --fail -H "X-IXP-Manager-API-Key: ${cfg.ixpManager.apiKey}" -o ${confPath}.new ${ixpmUrlConfig}/${handle}
          echo "Downloaded new config"
          echo "##########################################################"

          ${birdPkg}/bin/bird -p -c ${confPath}.new
          echo "Checked new config"
          echo "##########################################################"

          echo "Moving new config to main path"
          cp -f ${confPath}.new ${confPath}
          rm -f ${confPath}.new
          echo "##########################################################"

          echo "Checking BIRD operational status"
          ${birdPkg}/bin/birdc -s ${socketPath} show memory
          if [[ $? -eq 0 ]]; then
            echo "Bird detected online, running reconfigure"

            ${birdPkg}/bin/birdc -s ${socketPath} configure

            if [[ $? -ne 0 ]]; then
                echo "ERROR: Reconfigure failed for ${handle}"

                if [[ -e ${confPath}.old ]]; then
                    echo "  -> Trying to revert to previous"
                    mv ${confPath} ${confPath}.failed
                    mv ${confPath}.old ${confPath}
                    ${birdPkg}/bin/birdc -s ${socketPath} configure
                    if [[ $? -eq 0 ]]; then
                        echo "  -> Successfully reverted"
                    else
                        echo "  -> Reversion failed"
                        exit 6
                    fi
                fi
            fi

          else
              echo "BIRD not running - no reconfig"
          fi
          echo "##########################################################"

          echo "Script complete"
          exit 0
        '';

      ixpmReload4 = pkgs.writeShellScriptBin "reload4" (ixpmScriptGenerator cfg.ixpManager.rs4Handle rs4Config rs4Socket);
      ixpmReload6 = pkgs.writeShellScriptBin "reload6" (ixpmScriptGenerator cfg.ixpManager.rs6Handle rs6Config rs6Socket);

      ixpmReload4Wrapper = pkgs.writeShellScriptBin "ixpm-reload4" ''
        exec /run/wrappers/bin/sudo -u bird ${lib.getExe' ixpmReload4 "reload4"}
      '';
      ixpmReload6Wrapper = pkgs.writeShellScriptBin "ixpm-reload6" ''
        exec /run/wrappers/bin/sudo -u bird ${lib.getExe' ixpmReload6 "reload6"}
      '';

      birdwatcherConfigPath = "/etc/birdwatcher/birdwatcher.conf";
      birdwatcherSettings = ''
        [server]
        allow_from = []
        allow_uncached = false
        modules_enabled = ["status",
                            "protocols",
                            "protocols_bgp",
                            "protocols_short",
                            "routes_protocol",
                            "routes_peer",
                            "routes_table",
                            "routes_table_filtered",
                            "routes_table_peer",
                            "routes_filtered",
                            "routes_prefixed",
                            "routes_noexport",
                            "routes_pipe_filtered_count",
                            "routes_pipe_filtered"
                          ]

        [bird]
        listen = "0.0.0.0:17904"
        config = "${rs4Config}"
        birdc  = "${birdc4}"
        ttl = 1 # time to live (in minutes) for caching of cli output
        [bird6]
        listen = "0.0.0.0:17906"
        config = "${rs6Config}"
        birdc  = "${birdc6}"
        ttl = 1 # time to live (in minutes) for caching of cli output

        [cache]
        use_redis = false

        [housekeeping]
        interval = 5
        force_release_memory = true
      '';

      birdwatcherServiceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 15;
        User = "bird";
        Group = "bird";
        StateDirectoryMode = "0700";
        UMask = "0117";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        PrivateMounts = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "~@clock @privileged @cpu-emulation @debug @keyring @module @mount @obsolete @raw-io @reboot @setuid @swap";
        BindReadOnlyPaths = [
          "-/etc/resolv.conf"
          "-/etc/nsswitch.conf"
          "-/etc/ssl/certs"
          "-/etc/static/ssl/certs"
          "-/etc/hosts"
          "-/etc/localtime"
        ];
      };
    in {
      environment = {
        systemPackages = with pkgs; [
          bird2
          ixpmReload4Wrapper
          ixpmReload6Wrapper
        ];
        shellAliases = {
          inherit birdc4;
          inherit birdc6;
        };
      };

      systemd = {
        tmpfiles.settings."10-bird-routeservers" = {
          "/var/lib/bird".d = {
            user = "bird";
            group = "bird";
          };
          "/etc/bird".d = {
            user = "bird";
            group = "bird";
          };
          "/var/log/bird".d = {
            user = "bird";
            group = "bird";
            mode = "0664";
          };
        };

        services = let
          birdCaps = [
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
            "CAP_NET_RAW"
          ];

          birdServiceConfig = {
            Type = "forking";
            Restart = "on-failure";
            User = "bird";
            Group = "bird";
            StateDirectory = "bird";
            ReadWritePaths = [
              "/var/log"
            ];
            CapabilityBoundingSet = birdCaps;
            AmbientCapabilities = birdCaps;
            ProtectSystem = "full";
            ProtectHome = "yes";
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            PrivateTmp = true;
            PrivateDevices = true;
            SystemCallFilter = "~@cpu-emulation @debug @keyring @module @mount @obsolete @raw-io";
            MemoryDenyWriteExecute = "yes";
          };

          ixpmServiceConfig = {
            ReadWritePaths = [
              "/etc/bird"
            ];
            User = "bird";
            Group = "bird";
            StateDirectory = "bird";
            Type = "oneshot";
            Restart = "on-failure";
            ExecPaths = ["/nix/store"];
            NoExecPaths = ["/"];
          };
        in {
          ixpm-rs4 = {
            wantedBy = [
              "bird4.service"
            ];
            startAt = "hourly";
            serviceConfig = ixpmServiceConfig;
            script = ixpmScriptGenerator cfg.ixpManager.rs4Handle rs4Config rs4Socket;
          };
          ixpm-rs6 = {
            wantedBy = [
              "bird6.service"
            ];
            startAt = "hourly";
            serviceConfig = ixpmServiceConfig;
            script = ixpmScriptGenerator cfg.ixpManager.rs6Handle rs6Config rs6Socket;
          };
          bird4 = {
            description = "IPv4 Routeserver running BIRD Internet Routing Daemon";
            wantedBy = ["multi-user.target"];
            reloadTriggers = [
              rs4Config
            ];
            serviceConfig = mkMerge [
              birdServiceConfig
              {
                ExecStart = "${lib.getExe' birdPkg "bird"} -s ${rs4Socket}  -c ${rs4Config}";
                ExecReload = "${lib.getExe' birdPkg "birdc"} -s ${rs4Socket} configure";
                ExecStop = "${lib.getExe' birdPkg "birdc"} -s ${rs4Socket} down";
                RuntimeDirectory = "bird4";
              }
            ];
          };
          bird6 = {
            description = "IPv6 Routeserver running BIRD Internet Routing Daemon";
            wantedBy = ["multi-user.target"];
            reloadTriggers = [
              rs6Config
            ];
            serviceConfig = mkMerge [
              birdServiceConfig
              {
                ExecStart = "${lib.getExe' birdPkg "bird"} -s ${rs6Socket}  -c ${rs6Config}";
                ExecReload = "${lib.getExe' birdPkg "birdc"} -s ${rs6Socket} configure";
                ExecStop = "${lib.getExe' birdPkg "birdc"} -s ${rs6Socket} down";
                RuntimeDirectory = "bird6";
              }
            ];
          };

          birdwatcher4 = {
            description = "Birdwatcher HTTP API for the IPv4 Routeserver";
            wants = ["bird4.service" "network.target"];
            after = ["bird4.service" "network.target"];
            wantedBy = ["multi-user.target"];
            serviceConfig =
              birdwatcherServiceConfig
              // {
                ExecStart = "${lib.getExe pkgs.birdwatcher} -config ${birdwatcherConfigPath}";
              };
          };
          birdwatcher6 = {
            description = "Birdwatcher HTTP API for the IPv6 Routeserver";
            wants = ["bird6.service" "network.target"];
            after = ["bird6.service" "network.target"];
            wantedBy = ["multi-user.target"];
            serviceConfig =
              birdwatcherServiceConfig
              // {
                ExecStart = "${lib.getExe pkgs.birdwatcher} -config ${birdwatcherConfigPath} -6";
              };
          };
          prometheus-bird-exporter.serviceConfig = {
            User = "bird";
            Group = "bird";
          };
        };
      };

      services = {
        prometheus.exporters.bird = {
          enable = true;
          group = "bird";
          birdSocket = rs4Socket;
          extraFlags = [
            "-bird.socket6 ${rs6Socket}"
          ];
        };
      };

      environment.etc."birdwatcher/birdwatcher.conf".text = birdwatcherSettings;

      networking.firewall.extraInputRules = ''
        ip saddr 10.200.0.0/16 tcp dport { 17904, 17906 } accept
        tcp dport { 17904, 17906 } drop
      '';

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
    });
}
