/*
 *	validation.d
 */
module vlad.gpu.vulkan.validation;

import vlad.gpu.device;

version(Vulkan) { version(UseVulkanValidation) {
	import vlad.gpu.vulkan;
	import vlad.basis;
	import std.stdio;

	bool createDebugReportCallback(VkInstance instance, VkDebugReportFlagsEXT flags, VkDebugReportCallbackEXT* call_back)
	{
		VkDebugReportCallbackCreateInfoEXT info;
		info.pfnCallback = &messageCallback;
		info.flags = flags;

		VkResult ret = vkCreateDebugReportCallbackEXT(instance, &info, null, call_back);
		if (ret != VkResult.VK_SUCCESS)
		{
			writeln("Error : vkCreateDebugReportCallbackEXT() Failed.");
			return false;
		}
		return true;
	}
	extern(Windows) VkBool32 messageCallback(VkDebugReportFlagsEXT flags
							 , VkDebugReportObjectTypeEXT object_type
							 , uint64_t object
							 , size_t location
							 , int32_t msg_code
							 , const char* layer_prefix
							 , const char* message
							 , void* user_data) nothrow @nogc
	{
		bool is_error	= (0 != (flags & VK_DEBUG_REPORT_ERROR_BIT_EXT));
		bool is_warning	= (0 != (flags & VK_DEBUG_REPORT_WARNING_BIT_EXT));
		bool is_perf	= (0 != (flags & VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT));
		bool is_info	= (0 != (flags & VK_DEBUG_REPORT_INFORMATION_BIT_EXT));
		bool is_debug	= (0 != (flags & VK_DEBUG_REPORT_DEBUG_BIT_EXT));

		import core.stdc.stdio;
		printf("%s%s%s%s%s [%s] Code %d : %s\n"
				 , is_error		?"Error:\0".ptr:"\0".ptr
				 , is_warning	?"Warning:\0".ptr:"\0".ptr
				 , is_perf		?"Performance:\0".ptr:"\0".ptr
				 , is_info		?"Info:\0".ptr:"\0".ptr
				 , is_debug		?"Debug:\0".ptr:"\0".ptr
				 , layer_prefix
				 , msg_code
				 , message);
		return VK_FALSE;
	}
} } // Vulkan, UseVulkanDebug
