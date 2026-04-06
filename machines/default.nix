{
  pkgs,
  lib,
  ...
}: {
  nix = {
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "recursive-nix"
      ];
      system-features = ["recursive-nix"];
      trusted-users = ["root" "@wheel"];
      extra-substituters = ["https://nix-community.cachix.org"];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 2 --keep-since 14d";
    };
  };

  # Config sudo/doas commands
  security = {
    doas.enable = false;
    sudo = {
      enable = true;
      wheelNeedsPassword = lib.mkDefault false;
    };
  };

  networking = {
    enableIPv6 = true;
    hostName = lib.mkDefault "nixos";
    tempAddresses = lib.mkDefault "disabled";
    nftables.enable = true;
    firewall = {
      enable = lib.mkDefault false;
      allowPing = true;
    };
    useNetworkd = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # https://www.kernel.org/doc/html/latest/networking/ip-sysctl.html
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.accept_ra" = 0;
  };

  boot.growPartition = lib.mkDefault true;
}
