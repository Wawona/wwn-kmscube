# Native, static/in-process krh/vkcube for macOS. The archive uses only the
# Vulkan ABI and iland KMS/GBM contract, so Wawona may resolve it directly
# against either its MoltenVK default or KosmicKrisp Vulkan provider.
{
  lib,
  pkgs,
  buildModule,
  xcodeUtils,
  ...
}:

let
  iland = buildModule.buildForMacOS "iland" { };
in
pkgs.stdenv.mkDerivation {
  pname = "vkcube-macos";
  version = "0.1.0-ffd5669";

  src = ../../../upstream/vkcube;

  __noChroot = true;
  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    unset DEVELOPER_DIR
    MACOS_SDK=$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)
    if [ ! -d "$MACOS_SDK" ]; then
      MACOS_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
    fi
    if [ ! -d "$MACOS_SDK" ]; then
      MACOS_SDK=$(${xcodeUtils.findXcodeScript}/bin/find-xcode)/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
    fi
    test -d "$MACOS_SDK"

    CLANG="${pkgs.clang}/bin/clang"
    CFLAGS="-isysroot $MACOS_SDK -mmacosx-version-min=12.0 -fPIC -O2 -std=c11 \
      -I${iland}/include -I${pkgs.vulkan-headers}/include \
      -include ${iland}/include/iland_drm_open_compat.h"

    echo "CC libvkcube.a (native in-process vkcube_main)"
    "$CLANG" -c $CFLAGS -Dmain=vkcube_main main.c -o vkcube_main.o
    ar rcs libvkcube.a vkcube_main.o

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
    printf '%s\n' moltenvk kosmickrisp \
      > "$out/nix-support/required-vulkan-registry-providers"
    cat > "$out/nix-support/vkcube-build-metadata.json" <<'EOF'
    {
      "upstream": "krh/vkcube",
      "revision": "ffd566971fac916fc90d33a442369d5717ceb2a9",
      "presentation": "iland-kms-gbm",
      "defaultVulkanProvider": "moltenvk",
      "compatibleVulkanProviders": ["moltenvk", "kosmickrisp"],
      "translationLayers": []
    }
    EOF
  '';

  meta = with lib; {
    description = "Native in-process Vulkan cube over iland KMS/GBM for macOS";
    homepage = "https://github.com/krh/vkcube";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
