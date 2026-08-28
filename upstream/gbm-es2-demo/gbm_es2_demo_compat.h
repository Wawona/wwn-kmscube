/* Force-included for Apple + Android gbm_es2_demo builds over wwn-iland.
 *
 * Mode A has no Dobby open() hook. Use iland's store-safe /dev/dri/cardN
 * redirect (shared with kmscube / Weston). Also fix EGLNativeDisplayType
 * being an int on Apple platforms.
 */
#include <EGL/egl.h>
#include <stdint.h>
#include <iland_drm_open_compat.h>

/* This client runs in-process, linked as libgbm_es2_demo.a into the Wawona
 * host app (and even the standalone macOS binary shares this force-included
 * header). It therefore must NOT eglTerminate the process-wide ANGLE display
 * on teardown — a failed init would otherwise abort the whole host. The iland
 * EGL shim also refcounts the shared display, but this guard keeps the client
 * from ever asking for the terminate. A native-Linux reference build does not
 * force-include this header, so upstream teardown behaviour is preserved. */
#define WWN_ILAND_EMBEDDED 1

#define eglGetDisplay(dev) (eglGetDisplay)((EGLNativeDisplayType)(uintptr_t)(dev))

#if defined(WWN_ILAND_EMBEDDED)
#include <os/log.h>
static inline os_log_t wwn_gbm_es2_os_log(void) {
    static os_log_t log;
    if (!log) {
        log = os_log_create("com.aspauldingcode.Wawona", "gbm-es2");
    }
    return log;
}
#define WWN_GBM_LOG(fmt, ...) \
    os_log(wwn_gbm_es2_os_log(), fmt, ##__VA_ARGS__)
#else
#define WWN_GBM_LOG(fmt, ...) fprintf(stderr, fmt "\n", ##__VA_ARGS__)
#endif
