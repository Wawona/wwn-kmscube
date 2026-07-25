# opengl-cube over wwn-iland (GBM/EGL/DRM) + ANGLE — Apple mobile in-process archive.
#
# Same mesa/kmscube sources as the KMS Cube client, compiled with a distinct
# entry point so Machines can offer the two as separate ids. Deliberately NOT a
# second GLES cube implementation: see docs/issues/opengl-vulkan-cube-port.md,
# which locks this client to these sources rather than a GLFW demo port.
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
  angle = buildModule.buildForIOS "angle" { inherit simulator; };
  mobile = (import "${toolchainSrc}/dependencies/toolchains/apple-mobile-platform.nix") {
    inherit iosToolchain simulator;
  };
  sdkPlatform = mobile.sdkPlatform;
  minVerFlag = mobile.minVerFlag;
in
pkgs.stdenv.mkDerivation {
  pname = "opengl-cube-apple-mobile";
  version = "0.1.0";

  src = ../../../upstream;

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

    INCLUDES="-I${iland}/include -I${iland}/include/EGL -I${iland}/include/GLES2 -I${angle}/include"
    CFLAGS="-arch arm64 -isysroot $SDKROOT ${minVerFlag} -O2 -std=c11 \
      $INCLUDES -Wno-int-conversion -Wno-int-to-void-pointer-cast \
      -include kmscube_compat.h"

    echo "CC libopengl_cube.a (in-process opengl_cube_main)"
    "$CLANG" -c $CFLAGS -Dmain=opengl_cube_main kmscube.c -o opengl_cube_main.o
    "$CLANG" -c $CFLAGS esUtil.c -o esUtil.o
    "$AR" rcs libopengl_cube.a opengl_cube_main.o esUtil.o

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include $out/nix-support
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
    description = "OpenGL cube in-process archive over iland GBM/EGL/DRM + ANGLE";
    homepage = "https://github.com/Wawona/wwn-kmscube";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
