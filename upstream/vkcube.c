/*
 * Vulkan API smoke test for Wawona mobile targets.
 * Verifies VkInstance creation (SwiftShader / device loader) then exits.
 * Full swapchain-integrated vkcube rendering hooks into Wawona's Vulkan
 * compositor separately.
 */
#include <stdio.h>
#include <unistd.h>

#include <vulkan/vulkan.h>

int vkcube_main(int argc, char **argv) {
  (void)argc;
  (void)argv;
  VkApplicationInfo app_info = {
      .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
      .pApplicationName = "vkcube",
      .applicationVersion = 1,
      .pEngineName = "wwn-vkcube",
      .engineVersion = 1,
      .apiVersion = VK_API_VERSION_1_0,
  };
  VkInstanceCreateInfo create_info = {
      .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
      .pApplicationInfo = &app_info,
  };
  VkInstance instance = VK_NULL_HANDLE;
  VkResult vr = vkCreateInstance(&create_info, NULL, &instance);
  if (vr != VK_SUCCESS) {
    fprintf(stderr, "vkcube: vkCreateInstance failed (%d)\n", vr);
    return 1;
  }
  fprintf(stderr, "vkcube: Vulkan instance OK\n");
  for (int i = 0; i < 120; i++)
    usleep(16000);
  vkDestroyInstance(instance, NULL);
  return 0;
}
