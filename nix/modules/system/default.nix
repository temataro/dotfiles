{ ... }: {
  imports = [
    ./boot.nix
    ./networking.nix
    ./audio.nix
    ./display.nix
    ./fonts.nix
    ./packages.nix
  ];
}
