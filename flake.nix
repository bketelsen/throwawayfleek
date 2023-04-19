{
  inputs = {
    # Principle inputs (updated by `nix run .#update`)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-flake.url = "github:bketelsen/nixos-flake";
    fleek.url = "github:ublue-os/fleek";
  };

  outputs = inputs@{ self, ... }:
    let
      inherit (self) outputs;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      imports = [
        inputs.nixos-flake.flakeModule
        ./users
      ];
      perSystem = { self', pkgs, lib, config, inputs', ... }:
        {
          legacyPackages.homeConfigurations."${self.people.users.bjk}@beast" =
            self.nixos-flake.lib.mkHomeConfiguration
              pkgs
              ({ pkgs, ... }: {
                imports = [
                  self.homeModules.high
                  ./home/users/fleek
                  ./home/hosts/beast.nix
                  ./home/users/${self.people.users.bjk}/custom.nix
                ];
                home.username = "${self.people.users.bjk}";
                home.homeDirectory = "/${if pkgs.stdenv.isDarwin then "Users" else "home"}/${self.people.users.bjk}";
                home.stateVersion = "22.11";
              });
            # Enables 'nix run' to activate.
            apps.default.program = self'.packages.activate-home;
            # Enable 'nix build' to build the home configuration, but without
            # activating.
            apps.fleek.program = "${self.inputs.fleek.packages.${pkgs.system}.default}/bin/fleek";
            packages.default = self'.legacyPackages.homeConfigurations."${self.people.users.bjk}@beast".activationPackage;
        };

      flake = {
        imports = [
          ./users/default.nix
        ];
        # All home-manager configurations are kept here.
        templates.default = {
          description = "A `home-manager` template providing useful tools & settings for Nix-based development";
          path = builtins.path { path = inputs.nixpkgs.lib.cleanSource ./.; filter = path: _: baseNameOf path != "build.sh"; };
        };
        homeModules = inputs.nixpkgs.lib.genAttrs [ "high" "low" "none" "default" ] (x: ./home/bling/${x});
      };
    };
}
