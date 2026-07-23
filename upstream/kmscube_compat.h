/* Force-included for Apple (macOS + mobile) kmscube builds.
 *
 * 1) EGLNativeDisplayType is int on these platforms — eglGetDisplay takes an
 *    integer cast, not a pointer.
 * 2) In-process Wawona has no Dobby open() hook (wayland-mac is macOS
 *    bare-metal only). Map /dev/dri/card* opens to iland's virtual DRM fd (42)
 *    so init_drm() succeeds the same way drmOpen("virtual") would.
 */
#include <EGL/egl.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <stdarg.h>
#include <string.h>

#ifndef DRM_VIRTUAL_FD
#define DRM_VIRTUAL_FD 42
#endif

#define eglGetDisplay(dev) (eglGetDisplay)((EGLNativeDisplayType)(uintptr_t)(dev))

static inline int
wwn_kmscube_open(const char *path, int flags, ...)
{
	if (path && strncmp(path, "/dev/dri/card", 13) == 0) {
		const char *rest = path + 13;
		if (*rest >= '0' && *rest <= '9' && rest[1] == '\0')
			return DRM_VIRTUAL_FD;
	}

	typedef int (*open_fn)(const char *, int, ...);
	static open_fn real_open;
	if (!real_open) {
		real_open = (open_fn)dlsym(RTLD_NEXT, "open");
		if (!real_open)
			real_open = (open_fn)dlsym(RTLD_DEFAULT, "open");
	}
	if (!real_open)
		return -1;

	if (flags & O_CREAT) {
		va_list ap;
		va_start(ap, flags);
		int mode = va_arg(ap, int);
		va_end(ap);
		return real_open(path, flags, mode);
	}
	return real_open(path, flags);
}

#define open(...) wwn_kmscube_open(__VA_ARGS__)
