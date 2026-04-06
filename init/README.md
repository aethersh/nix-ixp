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

**After Install, safely unmount the disk**

```
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode unmount /tmp/disks.nix
```
