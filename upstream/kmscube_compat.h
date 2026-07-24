/* Force-included for Apple (macOS + mobile) kmscube builds.
 *
 * 1) EGLNativeDisplayType is int on these platforms — eglGetDisplay takes an
 *    integer cast, not a pointer.
 * 2) Mode A has no Dobby open() hook. Use iland's canonical store-safe
 *    /dev/dri/cardN redirect, shared with Weston and iland test clients.
 */
#include <EGL/egl.h>
#include <stdint.h>
#include <iland_drm_open_compat.h>

#define eglGetDisplay(dev) (eglGetDisplay)((EGLNativeDisplayType)(uintptr_t)(dev))
