{ pkgs, ... }:
{
  environment = {
    systemPackages = [
      pkgs.vscodium

      # Nix Tools
      pkgs.nixfmt-rfc-style # Formater for nix files
      pkgs.nil # Nix Language Server
    ];
  };
}
