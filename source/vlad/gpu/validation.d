/*
 *	validation.d
 */
module vlad.gpu.validation;

import vlad.basis;

version(Vulkan)
{
	import vlad.gpu.vulkan;
}

class GpuValidation
{
	this (Instance inst)
	{
		mInstance = inst;
		version(Vulkan) { version(UseVulkanValidation) {
		auto flag =		VK_DEBUG_REPORT_ERROR_BIT_EXT
					|	VK_DEBUG_REPORT_WARNING_BIT_EXT
					|	VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT
					|	VK_DEBUG_REPORT_INFORMATION_BIT_EXT
					;
		auto result = createDebugReportCallback(inst, flag, &mCallback);
		}}
	}

	void finalize()
	{
		version(Vulkan) { version(UseVulkanValidation) {
		vkDestroyDebugReportCallbackEXT(mInstance, mCallback, null);
		}}
	}
private:
	Instance mInstance;
	version(Vulkan) { version(UseVulkanValidation) {
		VkDebugReportCallbackEXT	mCallback;
	}}
}
