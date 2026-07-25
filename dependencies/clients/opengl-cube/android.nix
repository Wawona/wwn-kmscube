# opengl-cube for Android — c2d7fa/opengl-cube (CC0) ported onto iland userland
# KMS. A distinct demo from kmscube; needs GLES3 rather than GLES2.
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
  pname = "opengl-cube-android";
  version = "0.1.0";
  src = ../../../upstream;
  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    CC="${androidToolchain.androidCC}"
    AR="${androidToolchain.androidAR}"
    INCLUDES="-I. -I${iland}/include -I${iland}/include/EGL -I${iland}/include/GLES2 \
      -I${iland}/include/GLES3"
    CFLAGS="-fPIC -O2 -std=c11 $INCLUDES -include iland_drm_open_compat.h"
    "$CC" -c $CFLAGS -Dmain=opengl_cube_main opengl-cube/opengl_cube.c \
      -o opengl_cube_main.o
    "$AR" rcs libopengl_cube.a opengl_cube_main.o
    runHook postBuild
  '';
  installPhase = ''
    mkdir -p $out/lib $out/include
    cp libopengl_cube.a $out/lib/
    cat > $out/include/opengl_cube.h <<'EOF'
#ifndef WAWONA_OPENGL_CUBE_H
#define WAWONA_OPENGL_CUBE_H
int opengl_cube_main(int argc, char *argv[]);
#endif
EOF
  '';
  meta = with lib; {
    description = "OpenGL cube (iland KMS) in-process archive for Android";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
