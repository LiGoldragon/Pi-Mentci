{
  description = "Minimal Nix-packaged Pi environment for Mentci";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi-src = {
      url = "github:badlogic/pi-mono/v0.64.0";
      flake = false;
    };

    samskara-reader-src = {
      url = "github:LiGoldragon/samskara-reader";
      flake = false;
    };

    criome-cozo-src = {
      url = "github:LiGoldragon/criome-cozo";
      flake = false;
    };

    samskara-core-src = {
      url = "github:LiGoldragon/samskara-core";
      flake = false;
    };

    mentci-user-src = {
      url = "github:LiGoldragon/mentci-user";
      flake = false;
    };
  };

  outputs = inputs@{
    nixpkgs,
    flake-utils,
    crane,
    fenix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        rustToolchain = fenix.packages.${system}.stable.toolchain;
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        pi = import ./nix/pi.nix {
          inherit lib pkgs;
          src = inputs.pi-src;
        };

        piLinkupExtension = import ./nix/pi-linkup-extension.nix {
          inherit pkgs;
        };

        piInteractiveShellExtension = import ./nix/pi-interactive-shell-extension.nix {
          inherit pkgs;
        };

        piMcpAdapterExtension = import ./nix/pi-mcp-adapter-extension.nix {
          inherit pkgs;
        };

        samskaraReader = import ./nix/samskara-reader.nix {
          inherit craneLib pkgs;
          criomeCozoSrc = inputs.criome-cozo-src;
          samskaraCoreSrc = inputs.samskara-core-src;
          src = inputs.samskara-reader-src;
        };

        samskaraReaderMcp = import ./nix/samskara-reader-mcp.nix {
          inherit pkgs samskaraReader;
        };

        mentciUser = import ./nix/mentci-user.nix {
          inherit craneLib pkgs;
          src = inputs.mentci-user-src;
        };

        piMentci = import ./nix/pi-mentci.nix {
          inherit
            lib
            pkgs
            pi
            piInteractiveShellExtension
            piLinkupExtension
            piMcpAdapterExtension
            samskaraReaderMcp
            ;
        };

        devShell = import ./nix/dev-shell.nix {
          inherit pkgs piMentci mentciUser;
          mentciUserSrc = inputs.mentci-user-src;
        };

        packageCheck = import ./nix/package-check.nix {
          inherit pkgs piMentci samskaraReaderMcp;
        };
      in
      {
        packages = {
          inherit
            pi
            piInteractiveShellExtension
            piLinkupExtension
            piMcpAdapterExtension
            piMentci
            samskaraReader
            samskaraReaderMcp
            mentciUser
            ;
          default = piMentci;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = piMentci;
        };

        checks.default = packageCheck;

        devShells.default = devShell;

        formatter = pkgs.nixfmt;
      }
    );
}
