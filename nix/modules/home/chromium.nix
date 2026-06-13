{ ... }: {
  # Declarative Chromium: the browser package + force-installed extensions.
  #
  # NOTE: this manages the browser's *configuration*, not its profile state.
  # Your history, cookies, logins, open tabs, and per-extension settings live
  # in ~/.config/chromium and are deliberately NOT captured here — that data is
  # mutable, secret-laden, and does not belong in version control. To carry a
  # profile between machines, sign into Chrome sync or copy the profile dir by
  # hand; do not commit it.
  #
  # Extensions listed below are installed via the ExtensionInstallForcelist
  # policy. They cannot be manually removed from within the browser — remove the
  # entry here and rebuild instead. Extension *settings* are not declarative.
  programs.chromium = {
    enable = true;

    extensions = [
      { id = "cfhdojbkjhnklbpkdaibdccddilifddb"; } # Adblock Plus
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
      { id = "fdpohaocaechififmbbbbbknoalclacl"; } # GoFullPage - Full Page Screen Capture
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton Pass: Free Password Manager
      { id = "hdokiejnpimakedhajhdlcegeplioahd"; } # LastPass: Free Password Manager
      { id = "ipcjcbhpofedihcloggaichibomadlei"; } # AboveVTT
      { id = "jplgfhpmjnbigmhklmmbgecoobifkmpa"; } # Proton VPN: Fast & Secure
      { id = "mojanjniaionejccefgkjpplmfekilgg"; } # OneMonokai80s Browser Theme
      { id = "nffaoalbilbmmfgbnbgppjihopabppdk"; } # Video Speed Controller
    ];

    # Launch flags. None were set on the source machine (no chromium-flags.conf).
    # Common Wayland-native flags are left commented as a starting point:
    # commandLineArgs = [
    #   "--ozone-platform-hint=auto"
    #   "--enable-features=UseOzonePlatform"
    # ];
  };
}
