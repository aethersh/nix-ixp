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

  systemd.network.networks = {
    "10-mgmt" = {
      matchConfig = {
        MACAddress = "BC:24:11:8D:F9:A1";
        Type = "ether";
      };
      linkConfig = {
        Name = "nic0";
      };
      networkConfig = {
        DHCP = "yes";
      };
    };
  };
}
