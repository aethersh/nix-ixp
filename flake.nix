{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    deploy-rs,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
          inherit system;
        });

    deployPkgs = forEachSupportedSystem (
      {
        pkgs,
        system,
      }:
        import nixpkgs {
          inherit system;
          overlays = [
            deploy-rs.overlays.default # or deploy-rs.overlays.default
            (self: super: {
              deploy-rs = {
                inherit (pkgs) deploy-rs;
                inherit (super.deploy-rs) lib;
              };
            })
          ];
        }
    );
  in {
    formatter = forEachSupportedSystem ({pkgs, ...}: pkgs.alejandra);
    devShells = forEachSupportedSystem (
      {pkgs, ...}: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nixos-generators
            pkgs.deploy-rs
            pkgs.ragenix
            nh
          ];
        };
      }
    );

    nixosConfigurations = {
      mrs1 = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";

        specialArgs = {
          inherit system;
        };

        modules = [
          # Machine config
          ./machines
          ./machines/routeserver.nix
          ./machines/mrs1
        ];
      };
      mrs2 = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";

        specialArgs = {
          inherit system;
        };

        modules = [
          # Machine config
          ./machines
          ./machines/routeserver.nix
          ./machines/mrs2
        ];
      };
      monitor1 = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";

        specialArgs = {
          inherit system;
        };

        modules = [
          # Machine config
          ./machines
          ./machines/monitor1
        ];
      };
    };

    deploy = {
      fastConnection = true;
      remoteBuild = true;
      user = "root";
      sshUser = "admin";

      nodes = {
        mrs1 = {
          hostname = "mrs1.sbtnvt.vermont-ix.net";
          profiles.system.path =
            deployPkgs."x86_64-linux".deploy-rs.lib.activate.nixos
            self.nixosConfigurations.mrs1;
        };
        mrs2 = {
          hostname = "mrs2.sbtnvt.vermont-ix.net";
          profiles.system.path =
            deployPkgs."x86_64-linux".deploy-rs.lib.activate.nixos
            self.nixosConfigurations.mrs2;
        };
        monitor1 = {
          hostname = "monitor1.sbtnvt.vermont-ix.net";
          profiles.system.path =
            deployPkgs."x86_64-linux".deploy-rs.lib.activate.nixos
            self.nixosConfigurations.monitor1;
        };
      };
    };
  };
}
