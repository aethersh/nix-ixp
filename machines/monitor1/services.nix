{...}: {
  services = {
    # grafana = {
    #   enable = true;
    #   settings = {
    #     users = {
    #       # editors_can_admin = false;
    #       viewers_can_edit = false;
    #       allow_sign_up = false;
    #     };
    #     server.http_addr = "0.0.0.0";
    #     server.domain = "metrics.unicycl.ing";
    #     server.root_url = "https://metrics.unicycl.ing";
    #     server.enable_gzip = true;
    #     feature_toggles = {
    #       enable = ["ssoSettingsApi"];
    #     };
    #     feature_management = {
    #       allow_editing = true;
    #     };
    #   };
    #   provision.datasources.settings = {
    #     apiVersion = 1;

    #     datasources = [
    #       {
    #         name = "Victoria Metrics";
    #         type = "prometheus";
    #         url = "http://monitor1.sbtnvt.vermont-ix.net";
    #       }
    #     ];
    #   };
    # };
    alice-lg = {
      enable = true;
      settings = {
        server = {
          listen_http = "0.0.0.0:7340";
          enable_prefix_lookup = true;
          asn = 62848;
          routes_store_refresh_parallelism = 2;
          neighbors_store_refresh_parallelism = 2;
          routes_store_refresh_interval = 5;
          neighbors_store_refresh_interval = 5;
        };

        housekeeping = {
          interval = 5;
          force_release_memory = true;
        };

        # RS ASN 62848. Reason/RPKI large communities match IXP Manager's bird2-2025
        # route server template (community-filtering-definitions.foil.php), which
        # follows https://github.com/euro-ix/rs-workshop-july-2017/wiki/Route-Server-BGP-Community-usage
        rejection_reasons = {
          "62848:1101:1" = "Prefix length too long";
          "62848:1101:2" = "Prefix length too short";
          "62848:1101:3" = "Bogon prefix";
          "62848:1101:4" = "Bogon ASN in AS path";
          "62848:1101:5" = "AS path too long";
          "62848:1101:6" = "AS path too short";
          "62848:1101:7" = "First AS in path is not the peer's AS";
          "62848:1101:8" = "Next hop is not the peer's IP";
          "62848:1101:9" = "Prefix not permitted by peer's IRRDB prefix filter";
          "62848:1101:10" = "Origin AS not permitted by peer's IRRDB AS-SET";
          "62848:1101:11" = "Prefix not found in origin AS's IRRDB AS-SET";
          "62848:1101:12" = "RPKI validation state is unknown";
          "62848:1101:13" = "RPKI validation state is invalid";
          "62848:1101:14" = "Route learned via a transit-free/Tier-1 ASN";
          "62848:1101:15" = "Too many BGP communities attached";
        };

        rpki = {
          enabled = true;
          valid = "62848:1000:1";
          unknown = "62848:1000:2";
          not_checked = "62848:1000:3";
          invalid = "62848:1101:13";
        };

        "source.rs1-v4" = {
          name = "rs1.sbtnvt.vermont-ix.net (IPv4)";
          group = "Vermont-IX";
        };
        "source.rs1-v4.birdwatcher" = {
          api = "http://rs1.sbtnvt.vermont-ix.net:17904/";
          type = "multi_table";
          main_table = "master4";
          peer_table_prefix = "t_";
          pipe_protocol_prefix = "pp_";
          neighbors_refresh_timeout = 2;
        };

        "source.rs1-v6" = {
          name = "rs1.sbtnvt.vermont-ix.net (IPv6)";
          group = "Vermont-IX";
        };
        "source.rs1-v6.birdwatcher" = {
          api = "http://rs1.sbtnvt.vermont-ix.net:17906/";
          type = "multi_table";
          main_table = "master6";
          peer_table_prefix = "t_";
          pipe_protocol_prefix = "pp_";
          neighbors_refresh_timeout = 2;
        };

        "source.rs2-v4" = {
          name = "rs2.sbtnvt.vermont-ix.net (IPv4)";
          group = "Vermont-IX";
        };
        "source.rs2-v4.birdwatcher" = {
          api = "http://rs2.sbtnvt.vermont-ix.net:17904/";
          type = "multi_table";
          main_table = "master4";
          peer_table_prefix = "t_";
          pipe_protocol_prefix = "pp_";
          neighbors_refresh_timeout = 2;
        };

        "source.rs2-v6" = {
          name = "rs2.sbtnvt.vermont-ix.net (IPv6)";
          group = "Vermont-IX";
        };
        "source.rs2-v6.birdwatcher" = {
          api = "http://rs2.sbtnvt.vermont-ix.net:17906/";
          type = "multi_table";
          main_table = "master6";
          peer_table_prefix = "t_";
          pipe_protocol_prefix = "pp_";
          neighbors_refresh_timeout = 2;
        };
      };
    };

    victoriametrics = {
      enable = true;
      retentionPeriod = "45d";
      prometheusConfig = {
        scrape_configs = [
          {
            job_name = "node-exporter";
            metrics_path = "/metrics";
            static_configs = [
              {
                targets = ["monitor1.sbtnvt.vermont-ix.net:9100"];
              }
              {
                targets = ["akvorado.sbtnvt.vermont-ix.net:9100"];
              }
              {
                targets = ["rs1.sbtnvt.vermont-ix.net:9100"];
                labels.system = "routeserver";
              }
              {
                targets = ["rs2.sbtnvt.vermont-ix.net:9100"];
                labels.system = "routeserver";
              }
            ];
          }
          {
            job_name = "bird-exporter";
            metrics_path = "/metrics";
            static_configs = [
              {
                targets = ["rs1.sbtnvt.vermont-ix.net:9324"];
                labels.system = "routeserver";
              }
              {
                targets = ["rs2.sbtnvt.vermont-ix.net:9324"];
                labels.system = "routeserver";
              }
            ];
          }
        ];
      };
    };
  };
}
