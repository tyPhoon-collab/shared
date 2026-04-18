args@{
  config,
  pkgs,
  lib,
  username,
  homeDirectory,
  features ? { },
  ...
}:
let
  features = {
    desktop = false;
    fonts = false;
    extended = false;
    dev = 1;
    wsl = false;
  } // args.features;
in
{
  _module.args.features = features;

  imports = [
    ./modules/shell/shell.nix
    ./modules/programs/espanso.nix
    ./modules/programs/git.nix
    ./modules/programs/yazi.nix
    ./modules/programs/nixvim.nix
    ./modules/programs/wezterm.nix
    ./modules/platform/entrypoint.nix
  ];

  home.file.".config/nushell/aliases/git-aliases.nu".source = ./files/nushell/git-aliases.nu;
  home.file.".config/nushell/aliases/original-aliases.nu".source =
    ./files/nushell/original-aliases.nu;

  home.packages =
    with pkgs;
    [
      home-manager
      nix-output-monitor
      nvd
      gdu
      procs
      rsync
    ]
    ++ lib.optionals features.fonts [
      nerd-fonts.hack
    ]
    ++ lib.optionals features.extended [
      ffmpeg
      nixfmt
    ];

  programs.lazygit.enable = true;
  programs.bottom.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 10";
  };

  fonts.fontconfig.enable = features.fonts;

  home.username = username;
  home.homeDirectory = homeDirectory;

  home.stateVersion = "25.11";
}
