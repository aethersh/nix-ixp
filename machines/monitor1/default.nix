{...}: {
  imports = [
    ./hwconfig.nix
    ./services.nix
  ];

  networking = {
    hostName = "monitor1-sbtnvt";
    firewall.extraInputRules = ''
      ip saddr 10.200.0.0/16 tcp dport 7340 accept
      tcp dport 7340 drop
    '';
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
