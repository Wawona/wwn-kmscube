# vkcube for Android — Vulkan API smoke test archive.
{
  lib,
  pkgs,
  buildModule,
  androidToolchain ? (import "${toolchainSrc}/dependencies/toolchains/android.nix" {
    inherit lib pkgs;
  }),
  toolchainSrc ? null,
  ...
}:

let
  iland = buildModule.buildForAndroid "iland" { };
in
pkgs.stdenv.mkDerivation {
  pname = "vkcube-android";
  version = "0.1.0";
  src = ../../../upstream;
  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    CC="${androidToolchain.androidCC}"
    AR="${androidToolchain.androidAR}"
    INCLUDES=""
    CFLAGS="-fPIC -O2 -std=c11 $INCLUDES"
    "$CC" -c $CFLAGS vkcube.c -o vkcube_main.o
    "$AR" rcs libvkcube.a vkcube_main.o
    runHook postBuild
  '';
  installPhase = ''
    mkdir -p $out/lib $out/include
    cp libvkcube.a $out/lib/
    cat > $out/include/vkcube.h <<'EOF'
#ifndef WAWONA_VKCUBE_H
#define WAWONA_VKCUBE_H
int vkcube_main(int argc, char *argv[]);
#endif
EOF
  '';
  meta = with lib; {
    description = "Vulkan API smoke test in-process archive for Android";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
