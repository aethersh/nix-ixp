{...}: {
  networking.firewall = {
    enable = true;
    extraInputRules = ''
            ip saddr 149.112.81.0/24 tcp dport 179 accept
            ip6 saddr 2001:504:136::/48 tcp dport 179 accept
            tcp dport 179 drop
            ip saddr 10.200.10.0/24 tcp dport 22 accept
            tcp dport 22 drop
          '';
  };

  systemd.network = {
    networks = {
      "10-mgmt" = {
        matchConfig = {Name = "nic0";};
        networkConfig = {
          Description = "Backend Management NIC";
          DHCP = "yes";
        };
      };
      "20-vtix" = {
        matchConfig = {Name = "nic1";};
        networkConfig = {
          Description = "Vermont IX Peering Lan";
          DHCP = "no";
          IPv6AcceptRA = "no";
          IPv6SendRA = "no";
          EmitLLDP = "no";
        };
      };
    };
  };
}
