{...}: {
  vtix.routeserver = {
    enable = true;
    ixpManager.apiKey = "0HoSsYgJ3cuM4PmWl6V7ZjUFNjt5xRYeq4fRNr2R1CRDB0tK";
  };

  networking.firewall = {
    enable = true;
    extraInputRules = ''
      ip saddr 149.112.81.0/24 tcp dport 179 accept
      ip6 saddr 2001:504:136::/48 tcp dport 179 accept
      tcp dport 179 drop
    '';
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
