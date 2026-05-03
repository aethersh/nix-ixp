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
