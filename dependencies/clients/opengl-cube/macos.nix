# Standalone opengl-cube binary + in-process libopengl_cube.a for macOS
# (iland + ANGLE). Renders c2d7fa/opengl-cube — a different demo from kmscube —
# ported onto the same iland virtual DRM/GBM/EGL host. Needs GLES3 (VAOs,
# GLSL ES 300) where kmscube only needs GLES2.
{
  lib,
  pkgs,
  buildModule,
  xcodeUtils,
  ...
}:

let
  iland = buildModule.buildForMacOS "iland" { };
  angle = buildModule.buildForMacOS "angle" { };
in
pkgs.stdenv.mkDerivation {
  pname = "opengl-cube-macos";
  version = "0.1.0";

  src = ../../../upstream;

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
    if [ ! -d "$MACOS_SDK" ]; then
      echo "ERROR: MacOSX SDK not found." >&2
      exit 1
    fi
    export SDKROOT="$MACOS_SDK"

    CLANG="${pkgs.clang}/bin/clang"

    INCLUDES="-I. -I${iland}/include -I${iland}/include/EGL -I${iland}/include/GLES2 \
      -I${iland}/include/GLES3 -I${angle}/include"
    CFLAGS="-isysroot $SDKROOT -mmacosx-version-min=12.0 -O2 -std=c11 $INCLUDES \
      -Wno-int-conversion -Wno-int-to-void-pointer-cast -include kmscube_compat.h"

    FRAMEWORKS="-framework IOSurface -framework Foundation -framework CoreFoundation \
      -framework CoreGraphics -framework Accelerate -framework QuartzCore -framework Metal"
    LIBS="-L${iland}/lib -liland_userland -L${angle}/lib -lEGL -lGLESv2"

    # Output name differs from the source dir (./opengl-cube) so ld does not try
    # to overwrite a directory; installed as bin/opengl-cube below.
    echo "CC opengl-cube (standalone binary)"
    "$CLANG" $CFLAGS opengl-cube/opengl_cube.c $LIBS $FRAMEWORKS \
      -Wl,-rpath,${angle}/lib -o opengl_cube_bin

    echo "CC libopengl_cube.a (in-process opengl_cube_main)"
    "$CLANG" -c $CFLAGS -Dmain=opengl_cube_main opengl-cube/opengl_cube.c \
      -o opengl_cube_main.o
    ar rcs libopengl_cube.a opengl_cube_main.o

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib $out/include $out/nix-support
    cp opengl_cube_bin $out/bin/opengl-cube
    cp libopengl_cube.a $out/lib/
    cat > $out/include/opengl_cube.h <<'EOF'
#ifndef WAWONA_OPENGL_CUBE_H
#define WAWONA_OPENGL_CUBE_H
int opengl_cube_main(int argc, char *argv[]);
#endif
EOF
    echo "${angle}" > $out/nix-support/angle-path
    echo "${iland}" > $out/nix-support/iland-path
  '';

  meta = with lib; {
    description = "OpenGL cube GL smoke test over iland + ANGLE for macOS";
    homepage = "https://github.com/Wawona/wwn-kmscube";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
