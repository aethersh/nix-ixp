{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.vtix.routeserver;

  format = pkgs.formats.yaml {};

  rs4Socket = "/run/bird/bird-v4.ctl";
  rs6Socket = "/run/bird/bird-v6.ctl";

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
    in {
      environment = {
        systemPackages = with pkgs; [bird2];
        shellAliases = {
          inherit birdc4;
          inherit birdc6;
        };
      };

      systemd.services = let
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
          RuntimeDirectory = "bird";
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
            "/var/lib/bird"
          ];
          User = "bird";
          Group = "bird";
          Type = "oneshot";
          Restart = "on-failure";
          RuntimeDirectory = "bird";
          ExecPaths = ["/nix/store"];
          NoExecPaths = ["/"];
        };

        ixpmScript = let
          ixpmUrlLock = "${cfg.ixpManager.baseUrl}/api/v4/router/get-update-lock";
          ixpmUrlConfig = "${cfg.ixpManager.baseUrl}/api/v4/router/gen-config";
          ixpmUrlLockRelease = "${cfg.ixpManager.baseUrl}/api/v4/router/release-update-lock";
          ixpmUrlUpdated = "${cfg.ixpManager.baseUrl}/api/v4/router/updated";
        in
          handle: confPath: socketPath: ''
            VERBOSE=1

            function colourize() {
                local type message colour
                type=$1
                message=$2
                case "$type" in
                    "ERROR")
                        colour="\033[0;31m";;
                    "WARNING")
                        colour="\033[0;33m";;
                    "OK")
                        colour="\033[0;32m";;
                    *)
                        colour="\033[0m";;
                esac
                printf "''${colour}''${message}\033[0m"
            }

          ixpmScript = let
            ixpmUrlLock = "${cfg.ixpManager.baseUrl}/api/v4/router/get-update-lock";
            ixpmUrlConfig = "${cfg.ixpManager.baseUrl}/api/v4/router/gen-config";
            ixpmUrlLockRelease = "${cfg.ixpManager.baseUrl}/api/v4/router/release-update-lock";
            ixpmUrlUpdated = "${cfg.ixpManager.baseUrl}/api/v4/router/updated";
          in
            handle: confPath: socketPath: ''
              VERBOSE=1

              function colourize() {
                  local type message colour
                  type=$1
                  message=$2
                  case "$type" in
                      "ERROR")
                          colour="\033[0;31m";;
                      "WARNING")
                          colour="\033[0;33m";;
                      "OK")
                          colour="\033[0;32m";;
                      *)
                          colour="\033[0m";;
                  esac
                  printf "''${colour}''${message}\033[0m"
              }

              function verbose() {
                  if [[ $VERBOSE -eq 1 ]]; then
                      if [[ -n $2 ]]; then
                          colourize "''${2}" "''${1}"
                      else
                          echo -n "''${1}"
                      fi
                      if [[ -n $3 ]]; then
                          echo
                      fi
                  fi
              }

              function is_bird_running() {
                  local cmd bird_running

                  cmd="${birdPkg}/bin/birdc -s ${socketPath} show memory"
                  eval $cmd &>/dev/null
                  bird_running=$?

                  verbose "[fn is_bird_running] $cmd \$bird_running=''${bird_running}"

                  if [[ $bird_running -ne 0 ]]; then
                      verbose "[BIRD NOT RUNNING] " "WARNING"
                  fi

                  #NB: value of $bird_running is zero if it is running
                  return $bird_running
              }

              # if debug enabled, then verbose should be too
              if [[ $DEBUG -eq 1 ]] && [[ $VERBOSE -eq 1 ]]; then
                  VERBOSE=0
                  echo "WARNING: either verbose or debug mode should be use, verbose disabled"
              fi

              echo "Script started"

              if [[ -e ${confPath} ]]; then
                rm -f ${confPath}.old
                cp -f ${confPath} ${confPath}.old
                echo "Backed up old config to ${confPath}.old"
              fi

              rm -f ${confPath}.new
              ${pkgs.curl}/bin/curl --verbose --fail -H "X-IXP-Manager-API-Key: ${cfg.ixpManager.apiKey}" -o ${confPath}.new ${ixpmUrlConfig}/${handle}
              echo "Downloaded new config"

              ${birdPkg}/bin/bird -p -c ${confPath}.new
              echo "Checked new config"

              is_bird_running

              if [[ $? -eq 0 ]]; then
                echo "Bird detected online, running reconfigure"
                cp -f ${confPath}.new ${confPath}
                rm -f ${confPath}.new
                echo "Moving new config to main path"
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
                  echo "BIRD not running - no reconfig required"
              fi
              echo "Script complete"
              exit 0
            '';
        in {
          ixpm-reconfigure4 = {
            wantedBy = [
              "bird-rs4.service"
            ];
            serviceConfig = ixpmServiceConfig;
            script = ixpmScript cfg.ixpManager.rs4Handle rs4Config rs4Socket;
          };
          ixpm-reconfigure6 = {
            wantedBy = [
              "bird-rs6.service"
            ];
            serviceConfig = ixpmServiceConfig;
            script = ixpmScript cfg.ixpManager.rs6Handle rs6Config rs6Socket;
          };
          bird-rs4 = {
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
              }
            ];
          };
          bird-rs6 = {
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
              }
            ];
          };
        };
      };
      users = {
        users.bird = {
          description = "BIRD Internet Routing Daemon user";
          group = "bird";
          home = "/var/lib/bird";
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
