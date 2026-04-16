{...}: {
  imports = [
    ./hwconfig.nix
  ];

  networking = {
    hostName = "rs1-sbtnvt";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  vtix.routeserver.ixpManager = {
    rs4Handle = "rs1-sbtnvt-v4";
    rs6Handle = "rs1-sbtnvt-v6";
  };

  systemd.network = {
    links = {
      "10-mgmt-nic0" = {
        matchConfig = {
          MACAddress = "BC:24:11:8D:F9:A1";
          Type = "ether";
        };
        linkConfig = {
          Name = "nic0";
        };
      };
      "20-vtix-nic1" = {
        matchConfig = {
          MACAddress = "00:17:91:fe:ed:01";
          Type = "ether";
        };
        linkConfig = {
          Name = "nic1";
        };
      };
    };
    networks = {
      "20-vtix" = {
        addresses = [
          {
            Address = "149.112.81.1/25";
          }
          {
            Address = "2001:504:136::1791:feed:1/64";
          }
        ];
      };
    };
  };
}
