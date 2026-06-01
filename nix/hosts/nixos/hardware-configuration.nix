# ──────────────────────────────────────────────────────────────────────────────
# STUB — replace this file with the real output of nixos-generate-config.
#
# During a fresh install:
#   sudo nixos-generate-config --root /mnt
#   cp /mnt/etc/nixos/hardware-configuration.nix \
#      ~/dotfiles/nix/hosts/nixos/hardware-configuration.nix
#
# On a running NixOS system:
#   sudo nixos-generate-config
#   cp /etc/nixos/hardware-configuration.nix \
#      ~/dotfiles/nix/hosts/nixos/hardware-configuration.nix
# ──────────────────────────────────────────────────────────────────────────────
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # TODO: fill these in from the generated file
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules          = [];
  boot.kernelModules                 = [ "kvm-intel" ];
  boot.extraModulePackages           = [];

  # TODO: replace with your disk UUIDs (from blkid or nixos-generate-config output)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [];

  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
