#pragma once

#ifdef __ANDROID__

#include <dlfcn.h>
#include <stdio.h>

static void *wwn_vk_library;
static PFN_vkGetInstanceProcAddr wwn_vkGetInstanceProcAddr;
static PFN_vkGetDeviceProcAddr wwn_vkGetDeviceProcAddr;

#define WWN_VK_GLOBAL_FUNCTIONS(X) \
  X(vkEnumerateInstanceExtensionProperties) \
  X(vkCreateInstance)
#define WWN_VK_INSTANCE_FUNCTIONS(X) \
  X(vkEnumeratePhysicalDevices) \
  X(vkGetPhysicalDeviceMemoryProperties) \
  X(vkGetPhysicalDeviceQueueFamilyProperties) \
  X(vkEnumerateDeviceExtensionProperties) \
  X(vkCreateDevice) \
  X(vkDestroyInstance)
#define WWN_VK_DEVICE_FUNCTIONS(X) \
  X(vkGetDeviceQueue) \
  X(vkCreateCommandPool) \
  X(vkCreateBuffer) \
  X(vkGetBufferMemoryRequirements) \
  X(vkAllocateMemory) \
  X(vkBindBufferMemory) \
  X(vkMapMemory) \
  X(vkCreateRenderPass) \
  X(vkCreateDescriptorSetLayout) \
  X(vkCreatePipelineLayout) \
  X(vkCreateDescriptorPool) \
  X(vkAllocateDescriptorSets) \
  X(vkUpdateDescriptorSets) \
  X(vkCreateShaderModule) \
  X(vkCreateGraphicsPipelines) \
  X(vkDestroyShaderModule) \
  X(vkCreateImage) \
  X(vkGetImageMemoryRequirements) \
  X(vkBindImageMemory) \
  X(vkCreateImageView) \
  X(vkCreateFramebuffer) \
  X(vkAllocateCommandBuffers) \
  X(vkCreateFence) \
  X(vkWaitForFences) \
  X(vkResetFences) \
  X(vkResetCommandBuffer) \
  X(vkBeginCommandBuffer) \
  X(vkCmdBeginRenderPass) \
  X(vkCmdBindVertexBuffers) \
  X(vkCmdBindPipeline) \
  X(vkCmdBindDescriptorSets) \
  X(vkCmdSetViewport) \
  X(vkCmdSetScissor) \
  X(vkCmdDraw) \
  X(vkCmdEndRenderPass) \
  X(vkCmdCopyImageToBuffer) \
  X(vkEndCommandBuffer) \
  X(vkQueueSubmit) \
  X(vkDeviceWaitIdle) \
  X(vkDestroyFence) \
  X(vkUnmapMemory) \
  X(vkDestroyBuffer) \
  X(vkFreeMemory) \
  X(vkDestroyFramebuffer) \
  X(vkDestroyImageView) \
  X(vkDestroyImage) \
  X(vkDestroyDescriptorPool) \
  X(vkDestroyPipeline) \
  X(vkDestroyPipelineLayout) \
  X(vkDestroyDescriptorSetLayout) \
  X(vkDestroyRenderPass) \
  X(vkDestroyCommandPool) \
  X(vkDestroyDevice)

#define WWN_DECLARE_VK(name) static PFN_##name wwn_##name;
WWN_VK_GLOBAL_FUNCTIONS(WWN_DECLARE_VK)
WWN_VK_INSTANCE_FUNCTIONS(WWN_DECLARE_VK)
WWN_VK_DEVICE_FUNCTIONS(WWN_DECLARE_VK)
#undef WWN_DECLARE_VK

static int wwn_vkcube_load_global_dispatch(void) {
  const char *client_icd = getenv("WWN_SWIFTSHADER_LIBRARY");
  const char *path = client_icd && client_icd[0] ? client_icd : "libvulkan.so";
  wwn_vk_library = dlopen(path, RTLD_NOW | RTLD_LOCAL);
  if (!wwn_vk_library) {
    fprintf(stderr, "vkcube: cannot load Vulkan provider %s: %s\n", path,
            dlerror());
    return -1;
  }
  wwn_vkGetInstanceProcAddr =
      (PFN_vkGetInstanceProcAddr)dlsym(wwn_vk_library, "vkGetInstanceProcAddr");
  if (!wwn_vkGetInstanceProcAddr) {
    fprintf(stderr, "vkcube: %s has no vkGetInstanceProcAddr\n", path);
    return -1;
  }
#define WWN_LOAD_GLOBAL(name) \
  wwn_##name = (PFN_##name)wwn_vkGetInstanceProcAddr(VK_NULL_HANDLE, #name); \
  if (!wwn_##name) { \
    fprintf(stderr, "vkcube: missing global Vulkan entrypoint %s\n", #name); \
    return -1; \
  }
  WWN_VK_GLOBAL_FUNCTIONS(WWN_LOAD_GLOBAL)
#undef WWN_LOAD_GLOBAL
  return 0;
}

static int wwn_vkcube_load_instance_dispatch(VkInstance instance) {
#define WWN_LOAD_INSTANCE(name) \
  wwn_##name = (PFN_##name)wwn_vkGetInstanceProcAddr(instance, #name); \
  if (!wwn_##name) { \
    fprintf(stderr, "vkcube: missing instance Vulkan entrypoint %s\n", #name); \
    return -1; \
  }
  WWN_VK_INSTANCE_FUNCTIONS(WWN_LOAD_INSTANCE)
#undef WWN_LOAD_INSTANCE
  wwn_vkGetDeviceProcAddr = (PFN_vkGetDeviceProcAddr)
      wwn_vkGetInstanceProcAddr(instance, "vkGetDeviceProcAddr");
  return wwn_vkGetDeviceProcAddr ? 0 : -1;
}

static int wwn_vkcube_load_device_dispatch(VkDevice device) {
#define WWN_LOAD_DEVICE(name) \
  wwn_##name = (PFN_##name)wwn_vkGetDeviceProcAddr(device, #name); \
  if (!wwn_##name) { \
    fprintf(stderr, "vkcube: missing device Vulkan entrypoint %s\n", #name); \
    return -1; \
  }
  WWN_VK_DEVICE_FUNCTIONS(WWN_LOAD_DEVICE)
#undef WWN_LOAD_DEVICE
  return 0;
}

static void wwn_vkcube_close_dispatch(void) {
  if (wwn_vk_library)
    dlclose(wwn_vk_library);
  wwn_vk_library = NULL;
}

#define vkEnumerateInstanceExtensionProperties wwn_vkEnumerateInstanceExtensionProperties
#define vkCreateInstance wwn_vkCreateInstance
#define vkEnumeratePhysicalDevices wwn_vkEnumeratePhysicalDevices
#define vkGetPhysicalDeviceMemoryProperties wwn_vkGetPhysicalDeviceMemoryProperties
#define vkGetPhysicalDeviceQueueFamilyProperties wwn_vkGetPhysicalDeviceQueueFamilyProperties
#define vkEnumerateDeviceExtensionProperties wwn_vkEnumerateDeviceExtensionProperties
#define vkCreateDevice wwn_vkCreateDevice
#define vkDestroyInstance wwn_vkDestroyInstance
#define vkGetDeviceQueue wwn_vkGetDeviceQueue
#define vkCreateCommandPool wwn_vkCreateCommandPool
#define vkCreateBuffer wwn_vkCreateBuffer
#define vkGetBufferMemoryRequirements wwn_vkGetBufferMemoryRequirements
#define vkAllocateMemory wwn_vkAllocateMemory
#define vkBindBufferMemory wwn_vkBindBufferMemory
#define vkMapMemory wwn_vkMapMemory
#define vkCreateRenderPass wwn_vkCreateRenderPass
#define vkCreateDescriptorSetLayout wwn_vkCreateDescriptorSetLayout
#define vkCreatePipelineLayout wwn_vkCreatePipelineLayout
#define vkCreateDescriptorPool wwn_vkCreateDescriptorPool
#define vkAllocateDescriptorSets wwn_vkAllocateDescriptorSets
#define vkUpdateDescriptorSets wwn_vkUpdateDescriptorSets
#define vkCreateShaderModule wwn_vkCreateShaderModule
#define vkCreateGraphicsPipelines wwn_vkCreateGraphicsPipelines
#define vkDestroyShaderModule wwn_vkDestroyShaderModule
#define vkCreateImage wwn_vkCreateImage
#define vkGetImageMemoryRequirements wwn_vkGetImageMemoryRequirements
#define vkBindImageMemory wwn_vkBindImageMemory
#define vkCreateImageView wwn_vkCreateImageView
#define vkCreateFramebuffer wwn_vkCreateFramebuffer
#define vkAllocateCommandBuffers wwn_vkAllocateCommandBuffers
#define vkCreateFence wwn_vkCreateFence
#define vkWaitForFences wwn_vkWaitForFences
#define vkResetFences wwn_vkResetFences
#define vkResetCommandBuffer wwn_vkResetCommandBuffer
#define vkBeginCommandBuffer wwn_vkBeginCommandBuffer
#define vkCmdBeginRenderPass wwn_vkCmdBeginRenderPass
#define vkCmdBindVertexBuffers wwn_vkCmdBindVertexBuffers
#define vkCmdBindPipeline wwn_vkCmdBindPipeline
#define vkCmdBindDescriptorSets wwn_vkCmdBindDescriptorSets
#define vkCmdSetViewport wwn_vkCmdSetViewport
#define vkCmdSetScissor wwn_vkCmdSetScissor
#define vkCmdDraw wwn_vkCmdDraw
#define vkCmdEndRenderPass wwn_vkCmdEndRenderPass
#define vkCmdCopyImageToBuffer wwn_vkCmdCopyImageToBuffer
#define vkEndCommandBuffer wwn_vkEndCommandBuffer
#define vkQueueSubmit wwn_vkQueueSubmit
#define vkDeviceWaitIdle wwn_vkDeviceWaitIdle
#define vkDestroyFence wwn_vkDestroyFence
#define vkUnmapMemory wwn_vkUnmapMemory
#define vkDestroyBuffer wwn_vkDestroyBuffer
#define vkFreeMemory wwn_vkFreeMemory
#define vkDestroyFramebuffer wwn_vkDestroyFramebuffer
#define vkDestroyImageView wwn_vkDestroyImageView
#define vkDestroyImage wwn_vkDestroyImage
#define vkDestroyDescriptorPool wwn_vkDestroyDescriptorPool
#define vkDestroyPipeline wwn_vkDestroyPipeline
#define vkDestroyPipelineLayout wwn_vkDestroyPipelineLayout
#define vkDestroyDescriptorSetLayout wwn_vkDestroyDescriptorSetLayout
#define vkDestroyRenderPass wwn_vkDestroyRenderPass
#define vkDestroyCommandPool wwn_vkDestroyCommandPool
#define vkDestroyDevice wwn_vkDestroyDevice

#else

static int wwn_vkcube_load_global_dispatch(void) { return 0; }
static int wwn_vkcube_load_instance_dispatch(VkInstance instance) {
  (void)instance;
  return 0;
}
static int wwn_vkcube_load_device_dispatch(VkDevice device) {
  (void)device;
  return 0;
}
static void wwn_vkcube_close_dispatch(void) {}

#endif
