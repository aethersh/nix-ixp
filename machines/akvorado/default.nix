{...}: {
  imports = [
    ./hwconfig.nix
  ];

  networking = {
    hostName = "akvorado";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  systemd.network.links."10-mgmt-nic0" = {
    matchConfig = {
      MACAddress = "bc:24:11:66:22:94";
      Type = "ether";
    };
    linkConfig = {
      Name = "nic0";
    };
  };
}
