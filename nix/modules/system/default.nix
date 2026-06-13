{ ... }: {
  imports = [
    ./boot.nix
    ./networking.nix
    ./audio.nix
    ./display.nix
    ./fonts.nix
    ./hardware.nix
    ./services.nix
    ./packages.nix
  ];
}
