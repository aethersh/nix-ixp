{...}: {
  vtix.routeserver = {
    enable = true;
    generalConfig.cfg = {
      rs_as = 62848;
      rfc1997_wellknown_communities.policy = "pass";
      graceful_shutdown.enabled = true;
      filtering = {
        irrdb = {
          enforce_origin_in_as_set = true;
          enforce_prefix_in_as_set = true;
        };
        rpki_bgp_origin_validation = {
          enabled = true;
          reject_invalid = true;
        };
        ipv4_pref_len = {
          max = 24;
          min = 8;
        };
        ipv6_pref_len = {
          max = 48;
          min = 12;
        };
        reject_invalid_as_in_as_path = true;
        max_as_path_len = 32;
        transit_free = {
          action = "reject";
          asns = [
            174
            701
            1299
            2914
            3257
            3320
            3356
            5511
            6453
            6461
            6762
            6830
            7018
            12956
          ];
        };
        next_hop.policy = "strict";
      };
    };

    clientsConfig.clients = [
      {
        asn = "1351";
        cfg.filtering.irrdb.as_sets = ["AS-UVM"];
        ip = "142.112.81.3";
      }
    ];
  };

  networking.firewall = {
    enable = true;
    extraInputRules = ''
      ip saddr 149.112.81.0/24 tcp dport 179 accept
      ip6 saddr 2001:504:136::/48 tcp dport 179 accept
      tcp dport 179 drop
    '';
  };

  services.prometheus.exporters.bird = {
    enable = true;
    birdVersion = 2; # Explicitly set version, in case it gets upgraded and the default changes to 3 in the future
    group = "bird";
  } ;

  systemd.network.networks."20-vtix" = {
    matchConfig = {Name = "nic1";};
    networkConfig = {
      Description = "Vermont IX Peering Lan";
      DHCP = "no";
      IPv6AcceptRA = "no";
      IPv6SendRA = "no";
      EmitLLDP = "no";
    };
  };
}
