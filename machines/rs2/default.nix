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

  vtix.routeserver.ixpManager = {
    rs4Handle = "rs2-sbtnvt-v4";
    rs6Handle = "rs2-sbtnvt-v6";
  };

  systemd.network = {
    links = {
      "10-mgmt-nic0" = {
        matchConfig = {
          MACAddress = "BC:24:11:A4:16:7E";
          Type = "ether";
        };
        linkConfig.Name = "nic0";
      };
      "20-vtix-nic1" = {
        matchConfig = {
          MACAddress = "00:17:91:fe:ed:02";
          Type = "ether";
        };
        linkConfig.Name = "nic1";
      };
    };
    networks = {
      "20-vtix" = {
        addresses = [
          {
            Address = "149.112.81.2/24";
          }
          {
            Address = "2001:504:137::feed:2/64";
          }
        ];
      };
    };
  };
}
