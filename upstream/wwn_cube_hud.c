#include "wwn_cube_hud.h"

#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>

#ifdef WWN_CUBE_HUD_GL
/* GLES headers come from the including cube (ANGLE GLES2/GLES3). */
#endif

static const uint64_t wwn_hud_font[95] = {
    0x0000000000000000ULL, 0x0000040004040400ULL, 0x00000000000a0a00ULL,
    0x0000040e040e0400ULL, 0x0000040e040e0400ULL, 0x00000a0204080a00ULL,
    0x00000c0a040a0400ULL, 0x0000000000040400ULL, 0x0000080404040800ULL,
    0x0000020404040200ULL, 0x0000000a040a0000ULL, 0x000000040e040000ULL,
    0x0000020400000000ULL, 0x000000000e000000ULL, 0x0000040000000000ULL,
    0x0000020204080800ULL, 0x00000e0a0a0a0e00ULL, 0x00000e0404060400ULL,
    0x00000e020e080e00ULL, 0x00000e080e080e00ULL, 0x000008080e0a0a00ULL,
    0x00000e080e020e00ULL, 0x00000e0a0e020e00ULL, 0x0000040404080e00ULL,
    0x00000e0a0e0a0e00ULL, 0x00000e080e0a0e00ULL, 0x0000000400040000ULL,
    0x0000020400040000ULL, 0x0000080402040800ULL, 0x0000000e000e0000ULL,
    0x0000020408040200ULL, 0x0000040004080400ULL, 0x00000c020e0a0400ULL,
    0x00000a0a0e0a0400ULL, 0x0000060a060a0600ULL, 0x00000c0202020c00ULL,
    0x0000060a0a0a0600ULL, 0x00000e0206020e00ULL, 0x0000020206020e00ULL,
    0x00000c0a0a020c00ULL, 0x00000a0a0e0a0a00ULL, 0x00000e0404040e00ULL,
    0x0000040a08080800ULL, 0x00000a0a060a0a00ULL, 0x00000e0202020200ULL,
    0x00000a0a0e0e0a00ULL, 0x00000a0e0e0e0a00ULL, 0x0000040a0a0a0400ULL,
    0x00000202060a0600ULL, 0x00000c0e0a0a0400ULL, 0x00000a0a060a0600ULL,
    0x0000060804020c00ULL, 0x0000040404040e00ULL, 0x00000c0a0a0a0a00ULL,
    0x0000040a0a0a0a00ULL, 0x00000a0e0e0a0a00ULL, 0x00000a0a040a0a00ULL,
    0x00000404040a0a00ULL, 0x00000e0204080e00ULL, 0x00000c0404040c00ULL,
    0x0000080804020200ULL, 0x0000060404040600ULL, 0x00000000000a0400ULL,
    0x00000e0000000000ULL, 0x0000000000080400ULL, 0x00000a0a0e0a0400ULL,
    0x0000060a060a0600ULL, 0x00000c0202020c00ULL, 0x0000060a0a0a0600ULL,
    0x00000e0206020e00ULL, 0x0000020206020e00ULL, 0x00000c0a0a020c00ULL,
    0x00000a0a0e0a0a00ULL, 0x00000e0404040e00ULL, 0x0000040a08080800ULL,
    0x00000a0a060a0a00ULL, 0x00000e0202020200ULL, 0x00000a0a0e0e0a00ULL,
    0x00000a0e0e0e0a00ULL, 0x0000040a0a0a0400ULL, 0x00000202060a0600ULL,
    0x00000c0e0a0a0400ULL, 0x00000a0a060a0600ULL, 0x0000060804020c00ULL,
    0x0000040404040e00ULL, 0x00000c0a0a0a0a00ULL, 0x0000040a0a0a0a00ULL,
    0x00000a0e0e0a0a00ULL, 0x00000a0a040a0a00ULL, 0x00000404040a0a00ULL,
    0x00000e0204080e00ULL, 0x0000080406040800ULL, 0x0000040404040400ULL,
    0x000002040c040200ULL, 0x00000000060c0000ULL,
};

static double hud_now(void)
{
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return (double)tv.tv_sec + (double)tv.tv_usec * 1e-6;
}

static void hud_copy_trunc(char *dst, size_t n, const char *src)
{
  if (!dst || n == 0)
    return;
  if (!src || !src[0]) {
    dst[0] = '-';
    dst[1] = 0;
    return;
  }
  snprintf(dst, n, "%s", src);
}

static const char *hud_yn(int v) { return v ? "yes" : "no"; }

static void hud_classify_gl_renderer(char *dst, size_t n, const char *renderer)
{
  if (!renderer || !renderer[0]) {
    hud_copy_trunc(dst, n, "-");
    return;
  }
  if (strstr(renderer, "ANGLE"))
    snprintf(dst, n, "ANGLE");
  else if (strstr(renderer, "SwiftShader") || strstr(renderer, "swiftshader"))
    snprintf(dst, n, "SwiftShader");
  else if (strstr(renderer, "llvmpipe") || strstr(renderer, "llvmpipe"))
    snprintf(dst, n, "llvmpipe");
  else
    hud_copy_trunc(dst, n, renderer);
}

static void hud_classify_vk(char *dst, size_t n, const char *path,
                            const char *device)
{
  const char *icd = NULL;
  if (path) {
    if (strstr(path, "KosmicKrisp") || strstr(path, "kosmickrisp"))
      icd = "KosmicKrisp";
    else if (strstr(path, "MoltenVK") || strstr(path, "moltenvk"))
      icd = "MoltenVK";
    else if (strstr(path, "swiftshader") || strstr(path, "SwiftShader"))
      icd = "SwiftShader";
    else if (strstr(path, "libvulkan"))
      icd = "system Vulkan";
  }
  if (icd && device && device[0] && strcmp(device, "-") != 0)
    snprintf(dst, n, "%s (%s)", icd, device);
  else if (icd)
    snprintf(dst, n, "%s", icd);
  else
    hud_copy_trunc(dst, n, device);
}

void wwn_cube_hud_init(struct wwn_cube_hud *h)
{
  if (!h)
    return;
  memset(h, 0, sizeof(*h));
  hud_copy_trunc(h->client, sizeof(h->client), "-");
  hud_copy_trunc(h->vulkan_backend, sizeof(h->vulkan_backend), "-");
  hud_copy_trunc(h->opengl_backend, sizeof(h->opengl_backend), "-");
  h->fps_t0 = hud_now();
}

void wwn_cube_hud_set_client(struct wwn_cube_hud *h, const char *name)
{
  if (!h)
    return;
  hud_copy_trunc(h->client, sizeof(h->client), name);
}

void wwn_cube_hud_tick(struct wwn_cube_hud *h)
{
  if (!h)
    return;
  h->fps_frames++;
  double now = hud_now();
  double dt = now - h->fps_t0;
  if (dt >= 0.5) {
    h->fps = (float)(h->fps_frames / dt);
    h->fps_frames = 0;
    h->fps_t0 = now;
  }
}

void wwn_cube_hud_fill_gl(struct wwn_cube_hud *h)
{
#ifdef WWN_CUBE_HUD_GL
  if (!h)
    return;
  h->opengl = 1;
  const GLubyte *r = glGetString(GL_RENDERER);
  hud_classify_gl_renderer(h->opengl_backend, sizeof(h->opengl_backend),
                           r ? (const char *)r : NULL);
#else
  (void)h;
#endif
}

void wwn_cube_hud_set_vk(struct wwn_cube_hud *h, const char *provider_path,
                         const char *device_name)
{
  if (!h)
    return;
  h->vulkan = 1;
  hud_classify_vk(h->vulkan_backend, sizeof(h->vulkan_backend), provider_path,
                  device_name);
}

static uint64_t glyph_bits(int ch)
{
  if (ch < 32 || ch > 126)
    ch = '?';
  return wwn_hud_font[ch - 32];
}

static void put_px(uint8_t *rgba, int width, int height, int stride, int x,
                   int y, uint8_t r, uint8_t g, uint8_t b, uint8_t a, int bgra)
{
  if (x < 0 || y < 0 || x >= width || y >= height)
    return;
  uint8_t *p = rgba + (size_t)y * (size_t)stride + (size_t)x * 4u;
  if (bgra) {
    p[0] = b;
    p[1] = g;
    p[2] = r;
    p[3] = a;
  } else {
    p[0] = r;
    p[1] = g;
    p[2] = b;
    p[3] = a;
  }
}

static void draw_char(uint8_t *rgba, int width, int height, int stride, int x,
                      int y, int scale, int ch, int bgra)
{
  uint64_t bits = glyph_bits(ch);
  int row, col, sy, sx;
  for (row = 0; row < 8; row++) {
    unsigned g = (unsigned)((bits >> (8 * row)) & 0xFFu);
    for (col = 0; col < 8; col++) {
      if (!(g & (1u << col)))
        continue;
      for (sy = 0; sy < scale; sy++)
        for (sx = 0; sx < scale; sx++)
          put_px(rgba, width, height, stride, x + col * scale + sx,
                 y + row * scale + sy, 255, 255, 210, 255, bgra);
    }
  }
}

static void hud_format(const struct wwn_cube_hud *h, char *out, size_t n)
{
  snprintf(out, n,
           "client: %s\n"
           "fps: %.0f\n"
           "kms: %s\n"
           "drm: %s\n"
           "gbm: %s\n"
           "vulkan: %s\n"
           "OpenGL: %s\n"
           "vulkan backend: %s\n"
           "opengl backend: %s",
           h ? h->client : "-",
           h ? h->fps : 0.f,
           hud_yn(h ? h->kms : 0), hud_yn(h ? h->drm : 0),
           hud_yn(h ? h->gbm : 0), hud_yn(h ? h->vulkan : 0),
           hud_yn(h ? h->opengl : 0),
           h ? h->vulkan_backend : "-", h ? h->opengl_backend : "-");
}

void wwn_cube_hud_blit_rgba(uint8_t *rgba, int width, int height, int stride,
                            const struct wwn_cube_hud *h, int bgra)
{
  if (!rgba || width <= 0 || height <= 0 || stride < width * 4)
    return;

  char text[512];
  hud_format(h, text, sizeof(text));

  const int scale = (height >= 800) ? 3 : 2;
  const int pad = 10;
  const int gw = 8 * scale;
  const int gh = 8 * scale;
  int lines = 1;
  const char *s;
  for (s = text; *s; s++)
    if (*s == '\n')
      lines++;
  int maxc = 0, cur = 0;
  for (s = text; ; s++) {
    if (*s == '\n' || *s == 0) {
      if (cur > maxc)
        maxc = cur;
      cur = 0;
      if (!*s)
        break;
    } else {
      cur++;
    }
  }
  int box_w = pad * 2 + maxc * gw;
  int box_h = pad * 2 + lines * gh;
  if (box_w > width)
    box_w = width;
  if (box_h > height)
    box_h = height;

  int x, y;
  for (y = 0; y < box_h; y++) {
    for (x = 0; x < box_w; x++) {
      uint8_t *p = rgba + (size_t)y * (size_t)stride + (size_t)x * 4u;
      p[0] = (uint8_t)(p[0] / 5);
      p[1] = (uint8_t)(p[1] / 5);
      p[2] = (uint8_t)(p[2] / 5);
      p[3] = 220;
    }
  }

  int cx = pad, cy = pad;
  for (s = text; *s; s++) {
    if (*s == '\n') {
      cx = pad;
      cy += gh;
      continue;
    }
    draw_char(rgba, width, height, stride, cx, cy, scale, (unsigned char)*s,
              bgra);
    cx += gw;
  }
}

#ifdef WWN_CUBE_HUD_GL

static GLuint hud_prog;
static GLuint hud_tex;
static GLuint hud_vbo;
static int hud_tex_w, hud_tex_h;
static uint8_t *hud_scratch;
static int hud_scratch_n;

static const char *hud_vs =
    "#version 100\n"
    "attribute vec2 a_pos;\n"
    "attribute vec2 a_uv;\n"
    "varying vec2 v_uv;\n"
    "void main() {\n"
    "  gl_Position = vec4(a_pos, 0.0, 1.0);\n"
    "  v_uv = a_uv;\n"
    "}\n";

static const char *hud_fs =
    "#version 100\n"
    "precision mediump float;\n"
    "varying vec2 v_uv;\n"
    "uniform sampler2D u_tex;\n"
    "void main() {\n"
    "  gl_FragColor = texture2D(u_tex, v_uv);\n"
    "}\n";

static GLuint wwn_hud_compile_shader(GLenum type, const char *src)
{
  GLuint s = glCreateShader(type);
  glShaderSource(s, 1, &src, NULL);
  glCompileShader(s);
  return s;
}

static int hud_gl_ready(void)
{
  if (hud_prog)
    return 1;
  GLuint vs = wwn_hud_compile_shader(GL_VERTEX_SHADER, hud_vs);
  GLuint fs = wwn_hud_compile_shader(GL_FRAGMENT_SHADER, hud_fs);
  hud_prog = glCreateProgram();
  glAttachShader(hud_prog, vs);
  glAttachShader(hud_prog, fs);
  glBindAttribLocation(hud_prog, 0, "a_pos");
  glBindAttribLocation(hud_prog, 1, "a_uv");
  glLinkProgram(hud_prog);
  glDeleteShader(vs);
  glDeleteShader(fs);
  glGenTextures(1, &hud_tex);
  glGenBuffers(1, &hud_vbo);
  return hud_prog != 0;
}

void wwn_cube_hud_draw_gl(int fb_w, int fb_h, const struct wwn_cube_hud *h)
{
  if (fb_w <= 0 || fb_h <= 0 || !hud_gl_ready())
    return;

  int overlay_w = fb_w / 3;
  int overlay_h = fb_h / 4;
  if (overlay_w < 280)
    overlay_w = (fb_w < 280) ? fb_w : 280;
  if (overlay_h < 180)
    overlay_h = (fb_h < 180) ? fb_h : 180;
  if (overlay_w > fb_w)
    overlay_w = fb_w;
  if (overlay_h > fb_h)
    overlay_h = fb_h;

  int need = overlay_w * overlay_h * 4;
  if (!hud_scratch || hud_scratch_n < need) {
    free(hud_scratch);
    hud_scratch = (uint8_t *)calloc((size_t)need, 1);
    hud_scratch_n = need;
    if (!hud_scratch)
      return;
  } else {
    memset(hud_scratch, 0, (size_t)need);
  }

  wwn_cube_hud_blit_rgba(hud_scratch, overlay_w, overlay_h, overlay_w * 4, h, 0);

  GLint prev_prog = 0, prev_tex = 0, prev_buf = 0, prev_vao = 0;
  GLint prev_viewport[4];
  GLboolean prev_blend, prev_depth, prev_cull;
  glGetIntegerv(GL_CURRENT_PROGRAM, &prev_prog);
  glGetIntegerv(GL_TEXTURE_BINDING_2D, &prev_tex);
  glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &prev_buf);
#ifdef GL_VERTEX_ARRAY_BINDING
  glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &prev_vao);
#endif
  glGetIntegerv(GL_VIEWPORT, prev_viewport);
  prev_blend = glIsEnabled(GL_BLEND);
  prev_depth = glIsEnabled(GL_DEPTH_TEST);
  prev_cull = glIsEnabled(GL_CULL_FACE);

  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glViewport(0, 0, fb_w, fb_h);

  glBindTexture(GL_TEXTURE_2D, hud_tex);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  if (hud_tex_w != overlay_w || hud_tex_h != overlay_h) {
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, overlay_w, overlay_h, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, hud_scratch);
    hud_tex_w = overlay_w;
    hud_tex_h = overlay_h;
  } else {
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, overlay_w, overlay_h, GL_RGBA,
                    GL_UNSIGNED_BYTE, hud_scratch);
  }

  float ndc_w = 2.f * (float)overlay_w / (float)fb_w;
  float ndc_h = 2.f * (float)overlay_h / (float)fb_h;
  /* Top-left in GL NDC (y up): x=-1, y=1 */
  float x0 = -1.f, y1 = 1.f, x1 = -1.f + ndc_w, y0 = 1.f - ndc_h;
  float verts[] = {
      x0, y0, 0.f, 1.f, x1, y0, 1.f, 1.f, x0, y1, 0.f, 0.f, x1, y1, 1.f, 0.f,
  };

  glUseProgram(hud_prog);
  glBindBuffer(GL_ARRAY_BUFFER, hud_vbo);
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts), verts, GL_DYNAMIC_DRAW);
  glEnableVertexAttribArray(0);
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 16, (const void *)0);
  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 16, (const void *)8);
  GLint loc = glGetUniformLocation(hud_prog, "u_tex");
  if (loc >= 0)
    glUniform1i(loc, 0);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glDisableVertexAttribArray(0);
  glDisableVertexAttribArray(1);

  glUseProgram((GLuint)prev_prog);
  glBindTexture(GL_TEXTURE_2D, (GLuint)prev_tex);
  glBindBuffer(GL_ARRAY_BUFFER, (GLuint)prev_buf);
#ifdef GL_VERTEX_ARRAY_BINDING
  glBindVertexArray((GLuint)prev_vao);
#endif
  glViewport(prev_viewport[0], prev_viewport[1], prev_viewport[2],
             prev_viewport[3]);
  if (!prev_blend)
    glDisable(GL_BLEND);
  if (prev_depth)
    glEnable(GL_DEPTH_TEST);
  else
    glDisable(GL_DEPTH_TEST);
  if (prev_cull)
    glEnable(GL_CULL_FACE);
  else
    glDisable(GL_CULL_FACE);
}

#endif /* WWN_CUBE_HUD_GL */
