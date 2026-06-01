{ ... }: {
  # PipeWire replaces PulseAudio — pactl / pavucontrol still work via the
  # PulseAudio compatibility layer.
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  hardware.pulseaudio.enable = false;
  security.rtkit.enable      = true;
}
