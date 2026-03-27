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
      url = "github:badlogic/pi-mono/v0.62.0";
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
  };

  outputs = inputs@{
    self,
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
          inherit lib pkgs;
        };

        piSubagentsExtension = import ./nix/pi-subagents-extension.nix {
          inherit lib pkgs;
        };

        piSubagentsAdapter = import ./nix/pi-subagents-adapter.nix {
          inherit lib pkgs;
        };

        piMcpAdapterExtension = import ./nix/pi-mcp-adapter-extension.nix {
          inherit lib pkgs;
        };

        samskaraReader = import ./nix/samskara-reader.nix {
          inherit craneLib lib pkgs;
          criomeCozoSrc = inputs.criome-cozo-src;
          samskaraCoreSrc = inputs.samskara-core-src;
          src = inputs.samskara-reader-src;
        };

        samskaraReaderMcp = import ./nix/samskara-reader-mcp.nix {
          inherit lib pkgs samskaraReader;
        };

        piMentci = import ./nix/pi-mentci.nix {
          inherit
            lib
            pkgs
            pi
            piLinkupExtension
            piMcpAdapterExtension
            piSubagentsAdapter
            piSubagentsExtension
            samskaraReaderMcp
            ;
        };

        devShell = import ./nix/dev-shell.nix {
          inherit lib pkgs piMentci;
        };

        packageCheck = import ./nix/package-check.nix {
          inherit pkgs piMentci samskaraReaderMcp;
        };
      in
      {
        packages = {
          inherit
            pi
            piLinkupExtension
            piMcpAdapterExtension
            piSubagentsAdapter
            piSubagentsExtension
            piMentci
            samskaraReader
            samskaraReaderMcp
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
