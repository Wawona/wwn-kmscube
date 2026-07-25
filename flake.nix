{
  description = "wwn-kmscube: native OpenGL and Vulkan acceptance clients over wwn-iland KMS/GBM for Apple and Android.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.url = "github:Wawona/wwn-toolchain";
    wwn-toolchain.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.inputs.rust-overlay.follows = "rust-overlay";
    # L2 -> L1 edge; see Wawona/docs/wwn-repo-dag.md. Track development so
    # this leaf consumes the L1-owned MoltenVK/SwiftShader provider registry.
    wwn-iland.url = "github:Wawona/wwn-iland/development";
    wwn-iland.inputs.nixpkgs.follows = "nixpkgs";
    wwn-iland.inputs.wwn-toolchain.follows = "wwn-toolchain";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      wwn-toolchain,
      wwn-iland,
      ...
    }:
    let
      darwinSystems = [
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      allSystems = darwinSystems ++ linuxSystems;
      forAll = nixpkgs.lib.genAttrs allSystems;
      inherit (wwn-toolchain.lib) withPlatformVariants baseRegistry mkToolchains;

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true;
            android_sdk.accept_license = true;
          };
        };

      mkAndroidSDK =
        system: pkgs:
        let
          androidConfig = import "${wwn-toolchain}/dependencies/android/sdk-config.nix" {
            inherit system;
            lib = pkgs.lib;
          };
          androidComposition = pkgs.androidenv.composeAndroidPackages {
            cmdLineToolsVersion = "latest";
            platformToolsVersion = "latest";
            buildToolsVersions = [ androidConfig.buildToolsVersion ];
            platformVersions = [ (toString androidConfig.compileSdk) ];
            abiVersions = [ androidConfig.hostEmulatorAbi ];
            systemImageTypes = [ "google_apis_playstore" ];
            includeEmulator = androidConfig.emulatorSupported;
            includeSystemImages = androidConfig.emulatorSupported;
            includeNDK = true;
            includeCmake = true;
            ndkVersions = [ androidConfig.ndkVersion ];
            cmakeVersions = [ androidConfig.cmakeVersion ];
            useGoogleAPIs = false;
          };
          sdkRoot = "${androidComposition.androidsdk}/libexec/android-sdk";
        in
        {
          androidsdk = androidComposition.androidsdk;
          inherit sdkRoot;
          platformTools = androidComposition.platform-tools;
          cmdlineTools = androidComposition.androidsdk;
          buildTools = "${sdkRoot}/build-tools/${androidConfig.buildToolsVersion}";
          cmake = "${sdkRoot}/cmake/${androidConfig.cmakeVersion}";
          ndk = "${sdkRoot}/ndk/${androidConfig.ndkVersion}";
          emulator =
            if androidConfig.emulatorSupported then
              androidComposition.emulator
            else
              androidComposition.androidsdk;
          systemImage = "${sdkRoot}/system-images/android-${toString androidConfig.compileSdk}/google_apis_playstore/${androidConfig.hostEmulatorAbi}";
          androidSdkPackages = { };
          inherit androidConfig;
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
          wearos = ./dependencies/clients/vkcube/wearos.nix;
          ios = ./dependencies/clients/vkcube/ios.nix;
          ipados = ./dependencies/clients/vkcube/ipados.nix;
          visionos = ./dependencies/clients/vkcube/visionos.nix;
          macos = ./dependencies/clients/vkcube/macos.nix;
          # Product policy: tvOS/watchOS never bundle Vulkan.
          tvos = null;
          watchos = null;
          linux = null;
        };
        "opengl-cube" = withPlatformVariants {
          android = ./dependencies/clients/opengl-cube/android.nix;
          wearos = ./dependencies/clients/opengl-cube/wearos.nix;
          ios = ./dependencies/clients/opengl-cube/ios.nix;
          ipados = ./dependencies/clients/opengl-cube/ipados.nix;
          visionos = ./dependencies/clients/opengl-cube/visionos.nix;
          macos = ./dependencies/clients/opengl-cube/macos.nix;
          # Product policy: tvOS/watchOS never bundle ANGLE. Unlike kmscube (whose
          # tvos.nix re-exports ios.nix and is kept out by allowGpu alone), this
          # client refuses at the registry so a deps mistake cannot link it.
          tvos = null;
          watchos = null;
          linux = null;
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

      packages = forAll (
        system:
        let
          pkgs = pkgsFor system;
          androidSDK = mkAndroidSDK system pkgs;
          tc = mkToolchains {
            inherit pkgs androidSDK;
            pkgsAndroid = pkgs.pkgsCross.aarch64-android;
            androidAllowExperimentalFallback = builtins.elem system [
              "aarch64-darwin"
              "aarch64-linux"
            ];
            registry = baseRegistry // wwn-iland.registryFragment // self.registryFragment;
          };
          isDarwin = builtins.elem system darwinSystems;
        in
        (
          if isDarwin then
            {
              kmscube-ios = tc.buildForIOS "kmscube" { };
              kmscube-macos = tc.buildForMacOS "kmscube" { };
              vkcube-ios = tc.buildForIOS "vkcube" { };
              vkcube-ios-sim = tc.buildForIOS "vkcube" { simulator = true; };
              vkcube-ipados = tc.buildForIPadOS "vkcube" { };
              vkcube-visionos = tc.buildForVisionOS "vkcube" { };
              vkcube-visionos-sim = tc.buildForVisionOS "vkcube" { simulator = true; };
              vkcube-macos = tc.buildForMacOS "vkcube" { };
              opengl-cube-ios = tc.buildForIOS "opengl-cube" { };
              opengl-cube-ios-sim = tc.buildForIOS "opengl-cube" { simulator = true; };
              opengl-cube-ipados = tc.buildForIPadOS "opengl-cube" { };
              opengl-cube-visionos = tc.buildForVisionOS "opengl-cube" { };
              opengl-cube-macos = tc.buildForMacOS "opengl-cube" { };
            }
          else
            { }
        )
        // {
          vkcube-android = tc.buildForAndroid "vkcube" { };
          opengl-cube-android = tc.buildForAndroid "opengl-cube" { };
        }
      );

      formatter = forAll (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
