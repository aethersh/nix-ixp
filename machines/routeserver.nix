{...}: {
  vtix.routeserver = {
    enable = true;
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
  };

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
