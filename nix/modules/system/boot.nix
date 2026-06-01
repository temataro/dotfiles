{ pkgs, ... }: {
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Latest kernel for best hardware support on newer machines.
  # Switch to linuxPackages_lts for stability if needed.
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
