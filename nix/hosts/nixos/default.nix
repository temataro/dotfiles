{ config, pkgs, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/default.nix
  ];

  # TODO: replace with your machine's actual hostname
  networking.hostName = "belcher";

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store   = true;
  };

  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 14d";
  };

  users.users.tem = {
    isNormalUser = true;
    description  = "Temesgen Ataro";
    extraGroups  = [ "wheel" "networkmanager" "audio" "video" "podman" "dialout" ];
    shell        = pkgs.zsh;
  };

  # Must match home.stateVersion in home.nix — change both together on upgrades.
  system.stateVersion = "24.11";
}
