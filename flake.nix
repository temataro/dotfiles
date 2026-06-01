{
  description = "Temesgen's NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland from upstream for latest features; pinned to nixpkgs for glibc compat.
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs   = nixpkgs.legacyPackages.${system};
  in {
    # ── NixOS full system config ────────────────────────────────────────────
    # Replace "nixos" with your machine's hostname.
    # Before first build, run:  sudo nixos-generate-config --root /mnt
    # and copy the result into nix/hosts/nixos/hardware-configuration.nix
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; dotfiles = self; };
      modules = [
        ./nix/hosts/nixos/default.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs    = true;
          home-manager.useUserPackages  = true;
          home-manager.extraSpecialArgs = { inherit inputs; dotfiles = self; };
          home-manager.users.tem        = import ./nix/home.nix;
        }
      ];
    };

    # ── Standalone Home Manager ─────────────────────────────────────────────
    # Works on any Linux distro with nix installed (including Arch right now).
    # To activate:
    #   nix run home-manager/master -- switch --flake .#tem
    homeConfigurations.tem = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; dotfiles = self; };
      modules = [ ./nix/home.nix ];
    };
  };
}
