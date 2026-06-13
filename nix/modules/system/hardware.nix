{ config, pkgs, ... }: {
  # GPU + CPU microcode. Mapped from pacman: nvidia-open-dkms, nvidia-settings,
  # libva-nvidia-driver, amd-ucode.

  # AMD CPU microcode (amd-ucode). If this machine is Intel, swap for
  # hardware.cpu.intel.updateMicrocode instead.
  hardware.cpu.amd.updateMicrocode = true;

  # Graphics stack + NVIDIA VAAPI driver (libva-nvidia-driver)
  hardware.graphics = {
    enable        = true;
    enable32Bit   = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  };

  # NVIDIA with the open kernel modules (nvidia-open-dkms equivalent).
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open                = true;   # open GPU kernel modules
    modesetting.enable  = true;
    nvidiaSettings      = true;   # nvidia-settings GUI
    package             = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
