{...}: {
  imports = [
    ./hwconfig.nix
  ];

  networking = {
    hostName = "akvorado";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  systemd.network.links."10-mgmt-nic0" = {
    matchConfig = {
      MACAddress = "bc:24:11:66:22:94";
      Type = "ether";
    };
    linkConfig = {
      Name = "nic0";
    };
  };

  users.users.admin.extraGroups = ["podman"];
  environment.sessionVariables.CONTAINER_HOST = "unix:///run/podman/podman.sock";

  systemd = {
    tmpfiles.settings."10-akvorado-storage" = {
      "/mnt/fast/akvorado/kafka"."d".group = "podman";
      "/mnt/fast/akvorado/console"."d".group = "podman";
      "/mnt/fast/akvorado/run"."d".group = "podman";
      "/mnt/fast/akvorado/clickhouse"."d".group = "podman";
    };
    targets.akvorado.requires = ["podman-kafka.service" "podman-redis.service" "podman-orchestrator.service" "podman-inlet.service" "podman-console.service" "podman-outlet.service"];
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerSocket.enable = true;
      autoPrune.enable = true;
    };
    oci-containers = let
      # Shared declaration for akvorado container image
      image = "quay.io/akvorado/akvorado:2.3.0";

      autoRemoveOnStop = false;
      restartOption = "--restart=unless-stopped";

      akvoradoDir = ./akvorado-config;

      clickhouseServerXml = ./clickhouse/server.xml;
      clickhouseO11yXml = ./clickhouse/observability.xml;
    in {
      containers = {
        kafka = {
          image = "apache/kafka:4.2.0";
          inherit autoRemoveOnStop;
          extraOptions = [restartOption "--health-cmd=CMD,/opt/kafka/bin/kafka-topics.sh,--list,--bootstrap-server,kafka:9092"];
          volumes = ["/mnt/fast/akvorado/kafka:/var/lib/kafka/data"];
          environment = {
            # KRaft settings
            KAFKA_NODE_ID = "1";
            KAFKA_PROCESS_ROLES = "controller,broker";
            KAFKA_CONTROLLER_QUORUM_VOTERS = "1@kafka:9093";
            # Listeners
            KAFKA_LISTENERS = "CLIENT://:9092,CONTROLLER://:9093";
            KAFKA_LISTENER_SECURITY_PROTOCOL_MAP = "CLIENT:PLAINTEXT,CONTROLLER:PLAINTEXT";
            KAFKA_ADVERTISED_LISTENERS = "CLIENT://kafka:9092";
            KAFKA_CONTROLLER_LISTENER_NAMES = "CONTROLLER";
            KAFKA_INTER_BROKER_LISTENER_NAME = "CLIENT";
            # Misc
            KAFKA_DELETE_TOPIC_ENABLE = "true";
            KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR = "1";
            KAFKA_TRANSACTION_STATE_LOG_MIN_ISR = "1";
            KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR = "1";
            KAFKA_SHARE_COORDINATOR_STATE_TOPIC_REPLICATION_FACTOR = "1";
            KAFKA_SHARE_COORDINATOR_STATE_TOPIC_MIN_ISR = "1";
            KAFKA_LOG_DIRS = "/var/lib/kafka/data";
          };
        };
        redis = {
          image = "apache/kafka:4.2.0";
          inherit autoRemoveOnStop;
          extraOptions = [restartOption];
        };
        clickhouse = {
          # TODO: configuration files
          image = "clickhouse/clickhouse-server:26.3";
          inherit autoRemoveOnStop;
          extraOptions = [restartOption];
          environment = {
            CLICKHOUSE_INIT_TIMEOUT = "60";
            CLICKHOUSE_SKIP_USER_SETUP = "1";
          };
          capabilities = {
            SYS_NICE = true;
          };
          volumes = [
            "/mnt/fast/akvorado/clickhouse:/var/lib/clickhouse"
            "${clickhouseO11yXml}:/etc/clickhouse-server/config.d/observability.xml"
            "${clickhouseServerXml}:/etc/clickhouse-server/config.d/akvorado.xml"
          ];
        };

        # Akvorado Services
        orchestrator = {
          inherit image;
          cmd = ["orchestrator" "/etc/akvorado/akvorado.yaml"];
          inherit autoRemoveOnStop;
          extraOptions = [restartOption];
          dependsOn = ["kafka"];
          volumes = [
            "${akvoradoDir}:/etc/akvorado:ro"
          ];
        };
        console = {
          inherit image;
          cmd = ["console" "http://orchestrator:8080"];
          inherit autoRemoveOnStop;
          extraOptions = [restartOption];
          dependsOn = ["orchestrator" "redis" "clickhouse"];
          volumes = ["/mnt/fast/akvorado/console:/run/akvorado"];
          environment = {
            AKVORADO_CFG_CONSOLE_DATABASE_DSN = "/run/akvorado/console.sqlite";
          };
        };
        inlet = {
          inherit image;
          cmd = ["inlet" "http://orchestrator:8080"];
          inherit autoRemoveOnStop;
          extraOptions = [restartOption];
          dependsOn = ["orchestrator" "kafka"];
          volumes = ["/mnt/fast/akvorado/run:/run/akvorado"];
          ports = [
            "2055:2055/udp"
            "4739:4739/udp"
            "6343:6343/udp"
          ];
        };
        outlet = {
          inherit image;
          cmd = ["outlet" "http://orchestrator:8080"];
          inherit autoRemoveOnStop;
          extraOptions = [restartOption];
          dependsOn = ["orchestrator" "kafka" "clickhouse"];
          volumes = ["/mnt/fast/akvorado/run:/run/akvorado"];
          ports = [
            "10179:10179/tcp"
          ];
          environment = {
            AKVORADO_CFG_OUTLET_METADATA_CACHEPERSISTFILE = "/run/akvorado/metadata.cache";
            AKVORADO_CFG_OUTLET_FLOW_STATEPERSISTFILE = "/run/akvorado/flow.state";
          };
        };
      };
    };
  };
}
