{...}: {
  imports = [
    ./hwconfig.nix
  ];

  networking = {
    hostName = "mrs1-sbtnvt";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
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
    };
    networks = {
      "10-mgmt" = {
        matchConfig = {Name = "nic0";};
        networkConfig = {
          Description = "Backend Management NIC";
          DHCP = "yes";
        };
      };
    };
  };
}
