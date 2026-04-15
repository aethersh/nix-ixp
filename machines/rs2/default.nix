{...}: {
  imports = [
    ./hwconfig.nix
  ];

  networking = {
    hostName = "rs2-sbtnvt";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  vtix.routeserver = {
    generalConfig.cfg.router_id = "149.112.81.2";
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
      "20-vtix" = {
        addresses = [
          {
            Address = "149.112.81.2/25";
          }
          {
            Address = "2001:504:136::1791:feed:2/64";
          }
        ];
      };
    };
  };
}
