# Initialization Steps

## Setup Disks

This uses Disko, an automated partitioning tool.

**Download the config file**

```
curl https://raw.githubusercontent.com/aethersh/nix-ixp/refs/heads/main/init/disks.nix -o /tmp/disks.nix
```

**Edit if you need to change labels**

```
vi /tmp/disks.nix
```

**Run Format**

```
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount /tmp/disks.nix
```

Answer `yes` when prompted, and your disk will be mounted at `/mnt`!

## Configure and Install

Once the drive is mounted, you need to generate the hardware filesystem config. The command below outputs the `hardware-configuration.nix` with settings specific to that host machine. 

```
nixos-generate-config --root /mnt --show-hardware-config
```

### Create a nixosConfiguration 

If you haven't already, a `nixosConfiguration` entry must be created to control the machine. In the `machines` folder, each folder within that contains at least two files that set configuration for that machine specifically. The first is `default.nix`; there are a few basic settings that it must include, so here's a template:

```nix
{...}: {
  imports = [
    ./hwconfig.nix
  ];

  networking = {
    hostName = "<machine hostname>";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  # This locks the name of our network interface(s), which means we avoid future instability issues that can arise from this.
  systemd.network = {
    links = {
      "10-mgmt-nic0" = {
        matchConfig = {
          MACAddress = "<insert mac address from proxmox or where-ever here>";
          Type = "ether";
        };
        linkConfig = {
          Name = "nic0";
        };
      };
    };
  };
}
```

The second file is `hwconfig.nix`, which gets imported by the `default.nix` file and contains the output from `nixos-generate-config` above. 

You'll also have to import these things in `flake.nix` but that should be pretty straightforward for 

### Running Install

After those changes are made, push them to the GitHub repository, and note the 7-character hash of your latest commit. 

```
nixos-install --root /mnt --show-hardware-config
```

### After Install, safely unmount the disk

```
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode unmount /tmp/disks.nix
```

Then you can shutdown, remove any development stuff in Proxmox, and boot into your fresh NixOS config.
