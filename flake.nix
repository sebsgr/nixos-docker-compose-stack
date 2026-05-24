{
  description = "aformatik custom Nix packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }: {
      nixosModules =
        rec {
          default = {
            imports = [ ];
          };

          # Nur für Weiterentwicklung des Repositories gedacht.
          __codchi = {
            imports = [
              ./development/codchi.nix
              default
            ];
          };
        };
    };
}
