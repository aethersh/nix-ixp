{...}: {
  imports = [
    ./hwconfig.nix
  ];

  networking = {
    hostName = "vtix01";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  systemd.network.links."10-mgmt-nic0" = {
    matchConfig = {
      MACAddress = "BC:24:11:6A:8E:81";
      Type = "ether";
    };
    linkConfig = {
      Name = "nic0";
    };
  };
}
