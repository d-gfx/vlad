/**
 *	swapchain.d
 *
 *	Vulkan swap chain
 */
module vlad.gpu.vulkan.swapchain;

version(Vulkan) {
	import vlad.basis;
	import vlad.gpu.device;
	import vlad.gpu.vulkan;
	import std.stdio;
	import std.typecons;

	Tuple!(bool, "is_success", int, "swapchain_count", VkFormat, "fmt")
		createSwapchainVulkan(ref GpuDevice gpu, VkSwapchainKHR* swap_chain, ref VkSurfaceKHR surface, int width, int height)
	{
		with (gpu.mDevice) {
			// enumerate formats
			uint count  = 0;
			auto result = vkGetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &count, null);
			if (result != VkResult.VK_SUCCESS)
			{
				writeln("Error : vkGetPhysicalDeviceSurfaceFormatKHR() Failed.");
				return typeof(return)(false, -1, VK_FORMAT_UNDEFINED);
			}

			VkSurfaceFormatKHR[] formats;
			formats.length = count;
			result = vkGetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &count, formats.ptr);
			if (result != VkResult.VK_SUCCESS)
			{
				writeln("Error : vkGetPhysicalDeviceSUrfaceFormatsKHR() Failed.");
				return typeof(return)(false, -1, VK_FORMAT_UNDEFINED);
			}

			// print all supported formats
			foreach (ref f; formats)
			{
				writefln("fmt = %s, cl_space = %s", f.format, f.colorSpace);
			}
			// find format
			VkFormat		fmt			= VkFormat.VK_FORMAT_R8G8B8A8_UNORM;
			VkColorSpaceKHR	cl_space	= VK_COLORSPACE_SRGB_NONLINEAR_KHR;

			bool is_find = false;
			foreach (ref f; formats)
			{
				if (fmt == f.format && cl_space == f.colorSpace)
				{
					is_find = true; break;
				}
			}

			if (!is_find)
			{
				fmt			= formats[0].format;
				cl_space	= formats[0].colorSpace;
			}

			// Capability
			VkSurfaceCapabilitiesKHR caps;
			auto preTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR; // not transform
			{
				result = vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device,
																   surface,
																   &caps);
				if (result != VkResult.VK_SUCCESS)
				{
					writeln("Error : vkGetPhysicalDeviceSurfaceCapabilitiesKHR() Failed.");
					return typeof(return)(false, -1, VK_FORMAT_UNDEFINED);
				}

				if (!(caps.supportedTransforms & VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR))
				{
					preTransform = caps.currentTransform;
				}
			}

			// present mode
			auto present_mode = VkPresentModeKHR.VK_PRESENT_MODE_FIFO_KHR;
			{
				uint32_t mode_count;
				result = vkGetPhysicalDeviceSurfacePresentModesKHR(physical_device,
																   surface,
																   &mode_count,
																   null);
				if (result != VkResult.VK_SUCCESS)
				{
					writeln("Error : vkGetPhysicalDeviceSurfacePresentModesKHR() Failed.");
					return typeof(return)(false, -1, VK_FORMAT_UNDEFINED);
				}

				VkPresentModeKHR[] present_modes;
				present_modes.length = mode_count;
				result = vkGetPhysicalDeviceSurfacePresentModesKHR(physical_device,
																   surface,
																   &mode_count,
																   present_modes.ptr);
				if (result != VkResult.VK_SUCCESS)
				{
					writeln("Error : vkGetPhysicalDeviceSurfacePresentModesKHR() Failed.");
					return typeof(return)(false, -1, VK_FORMAT_UNDEFINED);
				}

				foreach (i; 0..mode_count)
				{
					if (present_modes[i] == VK_PRESENT_MODE_MAILBOX_KHR)
					{
						present_mode = VK_PRESENT_MODE_MAILBOX_KHR;
						break;
					}
					if (present_modes[i] == VK_PRESENT_MODE_IMMEDIATE_KHR)
					{
						present_mode = VK_PRESENT_MODE_IMMEDIATE_KHR;
					}
				}
			}

			// create swapchain
			uint32_t desiredSwapChainImageCount = caps.minImageCount + 1;
			if ((0 < caps.maxImageCount) && (caps.maxImageCount < desiredSwapChainImageCount))
			{
				desiredSwapChainImageCount = caps.maxImageCount;
			}

			{
				VkSwapchainCreateInfoKHR create_info;
				create_info.sType					= VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
				create_info.pNext					= null;
				create_info.flags					= 0;
				create_info.surface					= surface;
				create_info.minImageCount			= desiredSwapChainImageCount;
				create_info.imageFormat				= fmt;
				create_info.imageColorSpace			= cl_space;
				create_info.imageExtent				= VkExtent2D(width, height);
				create_info.imageArrayLayers		= 1;
				create_info.imageUsage				= VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
				create_info.imageSharingMode		= VK_SHARING_MODE_EXCLUSIVE;
				create_info.queueFamilyIndexCount	= 0;
				create_info.pQueueFamilyIndices		= null;
				create_info.preTransform			= preTransform;
				create_info.compositeAlpha			= VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
				create_info.presentMode				= present_mode;
				create_info.clipped					= VK_TRUE;
				create_info.oldSwapchain			= getNdHandleNull();

				result = vkCreateSwapchainKHR(device, &create_info, null, swap_chain);
				if (result != VkResult.VK_SUCCESS)
				{
					writeln( "Error : vkCreateSwapChainKHR() Failed." );
					return typeof(return)(false, -1, VK_FORMAT_UNDEFINED);
				}
			}

			writefln( "desiredSwapChainImageCount = %s", desiredSwapChainImageCount);
			uint32_t swap_chain_count = 0;

			// get swap chain count
			result = vkGetSwapchainImagesKHR(device, *swap_chain, &swap_chain_count, null);
			if (result != VK_SUCCESS)
			{
				writeln("Error : vkGetSwapchainImagesKHR() failed.");
				return typeof(return)(false, -1, VK_FORMAT_UNDEFINED);
			}
			writefln( "swap_chain_count = %s", swap_chain_count);
			return typeof(return)(true, swap_chain_count, fmt);
		} // with
	}
}
