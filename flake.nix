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
    ...
  }: let
    inherit (self) outputs;

    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {pkgs = import nixpkgs {inherit system;};});

    deployPkgs = forEachSupportedSystem (
      {
        pkgs,
        system,
        ...
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
    formatter = forEachSupportedSystem ({pkgs}: pkgs.alejandra);
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

  };
}
