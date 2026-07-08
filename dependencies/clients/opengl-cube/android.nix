# opengl-cube for Android — GLES cube via iland userland KMS (same sources as kmscube).
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
  kmscubeAndroid = buildModule.buildForAndroid "kmscube" { };
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
    INCLUDES="-I${iland}/include -I${iland}/include/EGL -I${iland}/include/GLES2"
    CFLAGS="-fPIC -O2 -std=c11 $INCLUDES"
    "$CC" -c $CFLAGS -Dmain=opengl_cube_main kmscube.c -o opengl_cube_main.o
    "$CC" -c $CFLAGS esUtil.c -o esUtil.o
    "$AR" rcs libopengl_cube.a opengl_cube_main.o esUtil.o
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
