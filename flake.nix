{
  description = "wwn-kmscube: Wawona's kmscube port (GBM/EGL/DRM GL smoke test over wwn-iland + ANGLE) for macOS, Apple mobile, and Android.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.url = "github:Wawona/wwn-toolchain";
    wwn-toolchain.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.inputs.rust-overlay.follows = "rust-overlay";
    wwn-iland.url = "github:Wawona/wwn-iland";
    wwn-iland.inputs.nixpkgs.follows = "nixpkgs";
    wwn-iland.inputs.wwn-toolchain.follows = "wwn-toolchain";
  };

  outputs = { self, nixpkgs, rust-overlay, wwn-toolchain, wwn-iland, ... }:
    let
      darwinSystems = [ "x86_64-darwin" "aarch64-darwin" ];
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      allSystems = darwinSystems ++ linuxSystems;
      forAll = nixpkgs.lib.genAttrs allSystems;
      inherit (wwn-toolchain.lib) withPlatformVariants baseRegistry mkToolchains;

      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          android_sdk.accept_license = true;
        };
      };

      kmscubeDir = ./dependencies/clients/kmscube;
    in
    {
      registryFragment = {
        kmscube = withPlatformVariants {
          android = kmscubeDir + "/android.nix";
          wearos = kmscubeDir + "/wearos.nix";
          ios = kmscubeDir + "/ios.nix";
          tvos = kmscubeDir + "/tvos.nix";
          ipados = kmscubeDir + "/ipados.nix";
          visionos = kmscubeDir + "/visionos.nix";
          watchos = kmscubeDir + "/watchos.nix";
          macos = kmscubeDir + "/macos.nix";
          linux = kmscubeDir + "/linux.nix";
        };
        vkcube = withPlatformVariants {
          android = ./dependencies/clients/vkcube/android.nix;
        };
        "opengl-cube" = withPlatformVariants {
          android = ./dependencies/clients/opengl-cube/android.nix;
        };
        # Backward-compatible alias for flakes that still key nativeDeps on this name.
        "iland-gl-clients" = withPlatformVariants {
          android = kmscubeDir + "/android.nix";
          wearos = kmscubeDir + "/wearos.nix";
          ios = kmscubeDir + "/ios.nix";
          tvos = kmscubeDir + "/tvos.nix";
          ipados = kmscubeDir + "/ipados.nix";
          visionos = kmscubeDir + "/visionos.nix";
          watchos = kmscubeDir + "/watchos.nix";
          macos = kmscubeDir + "/macos.nix";
          linux = null;
        };
      };

      packages = forAll (system:
        let
          pkgs = pkgsFor system;
          tc = mkToolchains {
            inherit pkgs;
            registry = baseRegistry // wwn-iland.registryFragment // self.registryFragment;
          };
          isDarwin = builtins.elem system darwinSystems;
        in
        (if isDarwin then {
          kmscube-ios = tc.buildForIOS "kmscube" { };
          kmscube-macos = tc.buildForMacOS "kmscube" { };
        } else { }));

      formatter = forAll (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
