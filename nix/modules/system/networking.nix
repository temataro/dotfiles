{ ... }: {
  networking.networkmanager.enable = true;

  # Firewall enabled; open ports as needed with networking.firewall.allowedTCPPorts
  networking.firewall.enable = true;
}
