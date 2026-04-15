{
  lib,
  pkgs,
  ...
}: {
  imports = [../modules];
  nix = {
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      allowed-users = [
        "admin"
        "root"
        "@wheel"
      ];
      trusted-users = [
        "admin"
        "root"
        "@wheel"
      ];
      system-features = ["recursive-nix"];
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

  time.timeZone = lib.mkDefault "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Config sudo/doas commands
  security = {
    doas.enable = false;
    sudo = {
      enable = true;
      wheelNeedsPassword = lib.mkDefault false;
    };
  };

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "bird"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQ2j1Tc6TMied/Hft9RWZpB+OFlN+TgsDikeJpe8elQ violet@aether"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINimhbJZN+MLdXbtk3Mrb5dca7P+LKy399OqqYZ122Ml henrik@nixos"
    ];
  };

  networking = {
    enableIPv6 = true;
    hostName = lib.mkDefault "nixos";
    tempAddresses = lib.mkDefault "disabled";
    nftables.enable = true;
    firewall = {
      enable = lib.mkDefault true;
      allowPing = true;
      extraInputRules = ''
        ip saddr 10.200.0.0/16 tcp dport 22 accept
        tcp dport 22 drop
      '';
    };
    useNetworkd = true;
  };

  systemd.network.networks."10-mgmt" = {
    matchConfig = {Name = "nic0";};
    networkConfig = {
      Description = "Backend Management NIC";
      DHCP = "yes";
    };
  };

  services = {
    qemuGuest.enable = true;
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
    iperf3.enable = true;
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
  };

  environment.systemPackages = with pkgs; [iperf3];

  # https://www.kernel.org/doc/html/latest/networking/ip-sysctl.html
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.accept_ra" = 0;
  };

  boot.growPartition = lib.mkDefault true;
}
