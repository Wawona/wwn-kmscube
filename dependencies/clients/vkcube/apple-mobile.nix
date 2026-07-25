# krh/vkcube over wwn-iland KMS/GBM + MoltenVK — Apple mobile archive.
# tvOS/watchOS deliberately have no registry variant: those products forbid
# Vulkan. iOS, iPadOS, and visionOS use the target-native MoltenVK static slice.
{
  lib,
  pkgs,
  buildModule,
  simulator ? false,
  iosToolchain,
  xcodeUtils ? iosToolchain,
  toolchainSrc ? null,
  ...
}:

let
  iland = buildModule.buildForIOS "iland" { inherit simulator; };
  mobile = (import "${toolchainSrc}/dependencies/toolchains/apple-mobile-platform.nix") {
    inherit iosToolchain simulator;
  };
  sdkPlatform = mobile.sdkPlatform;
  minVerFlag = mobile.minVerFlag;
in
pkgs.stdenv.mkDerivation {
  pname = "vkcube-apple-mobile";
  version = "0.1.0-ffd5669";

  src = ../../../upstream/vkcube;

  __noChroot = true;
  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    if [ -z "''${XCODE_APP:-}" ]; then
      XCODE_APP=$(${xcodeUtils.findXcodeScript}/bin/find-xcode || true)
      [ -n "$XCODE_APP" ] && export DEVELOPER_DIR="$XCODE_APP/Contents/Developer"
    fi
    export SDKROOT="$DEVELOPER_DIR/Platforms/${sdkPlatform}.platform/Developer/SDKs/${sdkPlatform}.sdk"
    CLANG="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
    AR="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar"

    CFLAGS="-arch arm64 -isysroot $SDKROOT ${minVerFlag} -fPIC -O2 -std=c11 \
      -I${iland}/include -I${pkgs.vulkan-headers}/include \
      -include ${iland}/include/iland_drm_open_compat.h"

    echo "CC libvkcube.a (native in-process vkcube_main)"
    "$CLANG" -c $CFLAGS -Dmain=vkcube_main main.c -o vkcube_main.o
    "$AR" rcs libvkcube.a vkcube_main.o

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p "$out/lib" "$out/include" "$out/nix-support"
    install -m644 libvkcube.a "$out/lib/"
    cat > "$out/include/vkcube.h" <<'EOF'
    #ifndef WAWONA_VKCUBE_H
    #define WAWONA_VKCUBE_H
    int vkcube_main(int argc, char *argv[]);
    #endif
    EOF
    echo "${iland}" > "$out/nix-support/iland-path"
    echo moltenvk > "$out/nix-support/required-vulkan-registry-providers"
    cat > "$out/nix-support/vkcube-build-metadata.json" <<'EOF'
    {
      "upstream": "krh/vkcube",
      "revision": "ffd566971fac916fc90d33a442369d5717ceb2a9",
      "presentation": "iland-kms-gbm",
      "vulkanProvider": "moltenvk-static",
      "translationLayers": []
    }
    EOF
  '';

  meta = with lib; {
    description = "Native in-process Vulkan cube over iland KMS/GBM for Apple mobile";
    homepage = "https://github.com/krh/vkcube";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
