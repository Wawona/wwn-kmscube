# Native krh/vkcube for Android — static/in-process Vulkan over iland KMS/GBM.
{
  lib,
  pkgs,
  buildModule,
  androidToolchain ? (
    import "${toolchainSrc}/dependencies/toolchains/android.nix" {
      inherit lib pkgs;
    }
  ),
  toolchainSrc ? null,
  ...
}:

let
  iland = buildModule.buildForAndroid "iland" { };
in
pkgs.stdenv.mkDerivation {
  pname = "vkcube-android";
  version = "0.1.0-ffd5669";
  src = ../../../upstream/vkcube;
  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    CC="${androidToolchain.androidCC}"
    AR="${androidToolchain.androidAR}"
    CFLAGS="-fPIC -O2 -std=c11 -I${iland}/include -I${pkgs.vulkan-headers}/include \
      -include ${iland}/include/iland_drm_open_compat.h"
    "$CC" -c $CFLAGS -Dmain=vkcube_main main.c -o vkcube_main.o
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
    printf '%s\n' system swiftshader turnip \
      > "$out/nix-support/required-vulkan-registry-providers"
    cat > "$out/nix-support/vkcube-build-metadata.json" <<'EOF'
    {
      "upstream": "krh/vkcube",
      "revision": "ffd566971fac916fc90d33a442369d5717ceb2a9",
      "presentation": "iland-kms-gbm",
      "defaultVulkanProvider": "system",
      "fallbackVulkanProvider": "swiftshader",
      "compatibleVulkanProviders": ["system", "swiftshader", "turnip"],
      "translationLayers": []
    }
    EOF
  '';
  meta = with lib; {
    description = "Native in-process Vulkan cube over iland KMS/GBM for Android";
    homepage = "https://github.com/krh/vkcube";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
