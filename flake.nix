{
  inputs = {
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-20.09";
    nixpkgs.url = "github:NixOS/nixpkgs/master";

    home.url = "github:rycee/home-manager";
    home.inputs.nixpkgs.follows = "nixos-unstable-small";

    nix.url = "github:NixOS/nix/master";
    # nix.inputs.nixpkgs.follows = "nixos-stable";

    dwarffs.url = "github:edolstra/dwarffs";
    dwarffs.inputs.nixpkgs.follows = "nixos-unstable-small";
    dwarffs.inputs.nix.follows = "nix";

    emacs.url = "github:nix-community/emacs-overlay";

    wayland.url = "github:colemickens/nixpkgs-wayland";
    wayland.inputs.nixpkgs.follows = "nixos-unstable-small";
    wayland.inputs.cachix.follows = "nixpkgs";

    mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
  };

  outputs = inputs:
    let
      allSystems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      diffTrace = left: right: string: value: if left != right then builtins.trace string value else value;

      inherit (builtins) attrNames attrValues readDir;
      inherit (lib) removeSuffix recursiveUpdate genAttrs filterAttrs mapAttrs;
      inherit (utils) pathsToImportedAttrs;

      config = {
        allowUnfree = true;
	android_sdk.accept_license = true;
      };

      channels = with inputs; {
        pkgs = inputs.nixos-unstable;
	modules = inputs.nixos-unstable;
	lib = inputs.nixos-unstable;
      };

      inherit (channels.lib) lib;

      utils = import ./lib/utils.nix { inherit lib; };

      system = "x86_64-linux";

      channelToOverlay = { system, config, flake, branch }: (final: prev: { ${flake} =
        mapAttrs (k: v: diffTrace (baseNameOf inputs.${flake}) (baseNameOf prev.path) "pkgs.${k} pinned to nixpkgs/${branch}" v)
	inputs.${flake}.legacyPackages.${system};
      });

      flakeToOverlay = { system, flake, name }: (final: prev: { ${flake} =
        mapAttrs (k: v: diffTrace (baseNameOf inputs.${flake}) (baseNameOf prev.path) "pkgs.${k} pinned to ${name}" v)
	inputs.${flake}.legacyPackages.${system};
      });

      pkgsForSystem = system: import channels.pkgs rec {
        inherit system config;

        overlays = (attrValues inputs.self.overlays) ++ 
        [
	  (channelToOverlay { inherit system config; flake = "nixpkgs"; branch = "master"; })
	  (channelToOverlay { inherit system config; flake = "nixos-unstable-small"; branch = "nixos-unstable-small"; })
	  (channelToOverlay { inherit system config; flake = "nixos-unstable"; branch = "nixos-unstable"; })
	  (channelToOverlay { inherit system config; flake = "nixos-stable"; branch = "nixos-20.09"; })

	  inputs.emacs.overlay
          (import inputs.mozilla)
          inputs.nix.overlay
          inputs.self.overlay
	];
      };

      forAllSystems = f: lib.genAttrs allSystems (system: f {
        inherit system;
	pkgs = pkgsForSystem system;
      });

    in {
      nixosConfigurations =
        let
	 pkgs = pkgsForSystem system;
	in
        import ./hosts {
	  inherit lib system utils pkgs inputs;
	};

      legacyPackages = forAllSystems ({ pkgs, ... }: pkgs);

      packages = forAllSystems ({ pkgs, ... }: lib.filterAttrs (_: p: (p.meta.broken or null) != true) {
      });

      overlay = import ./pkgs;

      overlays = lib.listToAttrs (map (name: {
        name = lib.removeSuffix ".nix" name;
	value = import (./overlays + "/${name}");
      }) (attrNames (readDir ./overlays)));

      nixosModules = let
        moduleList = (import ./modules/nixos.nix);
	modulesAttrs = pathsToImportedAttrs moduleList;

	profilesList = import ./profiles/list.nix;
	profilesAttrs = { profiles = pathsToImportedAttrs profilesList; };
      in
      modulesAttrs // profilesAttrs;

      devShell = forAllSystems ({ system, pkgs, ... }:
        let
	  configs = "${toString ./.}#nixosConfigurations";
	  build = "config.system.build";

          rebuild = pkgs.writeShellScriptBin "rebuild" ''
            if [ -n $2 ]; then
              sudo nixos-rebuild $1 --flake ${toString ./.}#$2
            else
              sudo nixos-rebuild $1 --flake ${toString ./.}
            fi
          '';
        in pkgs.mkShell {
          name = "dreyri-shell";

	  nativeBuildInputs = with pkgs; [
            git
	    git-crypt
	    nixFlakes
	    rebuild
	  ];

	  shellHook = ''
            PATH=${
              pkgs.writeShellScriptBin "nix" ''
                ${pkgs.nixFlakes}/bin/nix --option experimental-features "nix-command flakes ca-references" "$@"
              ''
            }/bin:$PATH
	  '';
        });
    };
}
