# Native, in-process krh/vkcube for macOS — Wayland client over iland's
# IOSurface dmabuf winsys (not the iland KMS host). Resolves Vulkan against
# MoltenVK or KosmicKrisp at runtime via WWN_VULKAN_LIBRARY.
{
  lib,
  pkgs,
  buildModule,
  xcodeUtils,
  ...
}:

let
  iland = buildModule.buildForMacOS "iland" { };
  libwayland = buildModule.buildForMacOS "libwayland" { };
  waylandProtocols = pkgs.wayland-protocols;
in
pkgs.stdenv.mkDerivation {
  pname = "vkcube-macos";
  version = "0.1.0-ffd5669";

  src = ../../../upstream/vkcube;

  __noChroot = true;
  dontConfigure = true;

  nativeBuildInputs = [ pkgs.wayland-scanner ];

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

    XDG_XML="${waylandProtocols}/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml"
    wayland-scanner client-header "$XDG_XML" xdg-shell-client-protocol.h
    wayland-scanner private-code  "$XDG_XML" xdg-shell-protocol.c

    CFLAGS="-isysroot $MACOS_SDK -mmacosx-version-min=12.0 -fPIC -O2 -std=c11 \
      -I. -I${iland}/include -I${pkgs.vulkan-headers}/include \
      -I${libwayland}/include"

    FRAMEWORKS="-framework IOSurface -framework Foundation -framework CoreFoundation \
      -framework CoreGraphics -framework QuartzCore -framework Metal -framework Accelerate"
    # Winsys (dmabuf post) lives in libiland_wayland_egl; core has no Wayland.
    # Optional WSI archive is not required for this client — it calls the
    # winsys present_pixels helper directly.
    LIBS="-L${iland}/lib -liland_wayland_egl -liland_userland \
      -L${libwayland}/lib -lwayland-client"

    echo "CC libvkcube.a (native in-process vkcube_main, Wayland)"
    "$CLANG" -c $CFLAGS -Dmain=vkcube_main main.c -o vkcube_main.o
    "$CLANG" -c $CFLAGS xdg-shell-protocol.c -o xdg-shell-protocol.o
    ar rcs libvkcube.a vkcube_main.o xdg-shell-protocol.o

    echo "CC vkcube (standalone binary)"
    "$CLANG" $CFLAGS main.c xdg-shell-protocol.c $LIBS $FRAMEWORKS \
      -Wl,-rpath,${libwayland}/lib -o vkcube_bin

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p "$out/bin" "$out/lib" "$out/include" "$out/nix-support"
    install -m755 vkcube_bin "$out/bin/vkcube"
    install -m644 libvkcube.a "$out/lib/"
    cat > "$out/include/vkcube.h" <<'EOF'
    #ifndef WAWONA_VKCUBE_H
    #define WAWONA_VKCUBE_H
    int vkcube_main(int argc, char *argv[]);
    #endif
    EOF
    echo "${iland}" > "$out/nix-support/iland-path"
    echo "${libwayland}" > "$out/nix-support/libwayland-path"
    printf '%s\n' moltenvk kosmickrisp \
      > "$out/nix-support/required-vulkan-registry-providers"
    cat > "$out/nix-support/vkcube-build-metadata.json" <<'EOF'
    {
      "upstream": "krh/vkcube",
      "revision": "ffd566971fac916fc90d33a442369d5717ceb2a9",
      "presentation": "wayland-iosurface-dmabuf",
      "defaultVulkanProvider": "moltenvk",
      "compatibleVulkanProviders": ["moltenvk", "kosmickrisp"],
      "translationLayers": []
    }
    EOF
  '';

  meta = with lib; {
    description = "Native in-process Vulkan cube over Wayland IOSurface dmabuf for macOS";
    homepage = "https://github.com/krh/vkcube";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
