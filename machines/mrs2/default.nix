{...}: {
  imports = [
    ./hwconfig.nix
  ];

  networking = {
    hostName = "mrs2-sbtnvt";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  systemd.network = {
    links = {
      "10-mgmt-nic0" = {
        matchConfig = {
          MACAddress = "BC:24:11:A4:16:7E";
          Type = "ether";
        };
        linkConfig = {
          Name = "nic0";
        };
      };
      "20-vtix-nic1" = {
        matchConfig = {
          MACAddress = "00:17:91:fe:ed:02";
          Type = "ether";
        };
        linkConfig = {
          Name = "nic1";
        };
      };
    };
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
