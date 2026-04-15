{...}: {
  imports = [
    ./hwconfig.nix
  ];

  networking = {
    hostName = "monitor1-sbtnvt";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  systemd.network.links."10-mgmt-nic0" = {
    matchConfig = {
      MACAddress = "bc:24:11:0c:a1:c3";
      Type = "ether";
    };
    linkConfig = {
      Name = "nic0";
    };
  };
}
