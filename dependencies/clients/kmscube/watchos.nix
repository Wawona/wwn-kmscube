# watchOS: no Metal / DRM / ANGLE. A real kmscube archive would include
# iland_drm_open_compat.h and xf86drm.h from iOS iland. The watch iland
# recipe is a stub, so this archive only satisfies the weston GL probe
# link (enableGlClients on watch weston).
{ lib, pkgs, ... }:

pkgs.runCommand "kmscube-watchos-stub-0.1.0" {
  nativeBuildInputs = [ pkgs.binutils ];
} ''
  mkdir -p "$out/lib" "$out/include" "$out/nix-support"
  cat > "$out/include/kmscube.h" <<'H'
#ifndef WAWONA_KMSCUBE_H
#define WAWONA_KMSCUBE_H
int kmscube_main(int argc, char *argv[]);
#endif
H
  cat > stub.c <<'C'
int kmscube_main(int argc, char *argv[]) {
  (void)argc;
  (void)argv;
  return 1;
}
C
  cc -c -o stub.o stub.c
  ar rcs "$out/lib/libkmscube.a" stub.o
  echo stub > "$out/nix-support/link-kind"
''
