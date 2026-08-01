/* Force-included for Apple + Android gbm_es2_demo builds over wwn-iland.
 *
 * Mode A has no Dobby open() hook. Use iland's store-safe /dev/dri/cardN
 * redirect (shared with kmscube / Weston). Also fix EGLNativeDisplayType
 * being an int on Apple platforms.
 */
#include <EGL/egl.h>
#include <stdint.h>
#include <iland_drm_open_compat.h>

#define eglGetDisplay(dev) (eglGetDisplay)((EGLNativeDisplayType)(uintptr_t)(dev))
