/**
*	swapchain.d
*/
module vlad.gpu.swapchain;

import vlad.basis;
import vlad.gpu.device;
import std.stdio;

version(Vulkan)
{
	import vlad.gpu.vulkan;
}

version(Windows)
{
	import core.sys.windows.windows;
}

class SwapChain
{
	struct InitArg
	{
		int width;
		int height;
		GpuDevice gpu;
		version(Vulkan)
		{
			version(Windows)
			{
				Instance inst;
				HINSTANCE h_inst;
				HWND hwnd;
			}
		}
	};

	bool init(ref InitArg arg)
	{
		bool is_success = false;
		version(Vulkan)
		{
			version(Windows)
			{
				is_success = createSurface(arg.inst, arg.h_inst, arg.hwnd);
				if (!is_success)
				{
					writeln("Error : SwapChain.createSurface (Windows) failed.");
					return false;
				}
			}
		}
		is_success = createSwapchain(arg.gpu, arg.width, arg.height);
		if (!is_success)
		{
			writeln("Error : SwapChain.createSwapchain failed.");
			return false;
		}

		is_success = createSwapchainImages(arg.gpu);
		if (!is_success)
		{
			writeln("Error : SwapChain.createSwapchainImages failed.");
			return false;
		}

		return is_success;
	}

	version(Vulkan)
	{
		version(Windows)
		{
			bool createSurface(Instance inst, HINSTANCE h_inst, HWND hwnd)
			{
				VkWin32SurfaceCreateInfoKHR	surface_info;
				surface_info.sType			= VkStructureType.VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
				surface_info.pNext			= null;
				surface_info.flags			= 0;
				surface_info.hinstance		= h_inst;
				surface_info.hwnd			= hwnd;

				auto result = vkCreateWin32SurfaceKHR(inst, &surface_info, null, &mSurface);
				if (result != VkResult.VK_SUCCESS)
				{
					writeln("Error : vkCreateWin32SurfaceKHR() Failed.");
					return false;
				}
				return true;
			}
		}
	}
	bool createSwapchain(ref GpuDevice gpu, int width, int height)
	{
		version(Vulkan)
		{
			// enumerate formats
			uint count  = 0;
			auto result = vkGetPhysicalDeviceSurfaceFormatsKHR(gpu.physical_device, mSurface, &count, null);
			if (result != VkResult.VK_SUCCESS)
			{
				writeln("Error : vkGetPhysicalDeviceSurfaceFormatKHR() Failed.");
				return false;
			}

			VkSurfaceFormatKHR[] formats;
			formats.length = count;
			result = vkGetPhysicalDeviceSurfaceFormatsKHR(gpu.physical_device, mSurface, &count, formats.ptr);
			if (result != VkResult.VK_SUCCESS)
			{
				writeln("Error : vkGetPhysicalDeviceSUrfaceFormatsKHR() Failed.");
				return false;
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
				result = vkGetPhysicalDeviceSurfaceCapabilitiesKHR(
																   gpu.physical_device,
																   mSurface,
																   &caps);
				if (result != VkResult.VK_SUCCESS)
				{
					writeln("Error : vkGetPhysicalDeviceSurfaceCapabilitiesKHR() Failed.");
					return false;
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
				result = vkGetPhysicalDeviceSurfacePresentModesKHR(
																   gpu.physical_device,
																   mSurface,
																   &mode_count,
																   null);
				if (result != VkResult.VK_SUCCESS)
				{
					writeln("Error : vkGetPhysicalDeviceSurfacePresentModesKHR() Failed.");
					return false;
				}

				VkPresentModeKHR[] present_modes;
				present_modes.length = mode_count;
				result = vkGetPhysicalDeviceSurfacePresentModesKHR(
																   gpu.physical_device,
																   mSurface,
																   &mode_count,
																   present_modes.ptr);
				if (result != VkResult.VK_SUCCESS)
				{
					writeln("Error : vkGetPhysicalDeviceSurfacePresentModesKHR() Failed.");
					return false;
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
				create_info.surface					= mSurface;
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
				create_info.oldSwapchain			= getHandleNull();

				result = vkCreateSwapchainKHR(gpu.device, &create_info, null, &mSwapchain);
				if (result != VkResult.VK_SUCCESS)
				{
					writeln( "Error : vkCreateSwapChainKHR() Failed." );
					return false;
				}
				// remember host device
				mHostDevice = gpu.device;
			}
		}
		return true;
	}
	bool createSwapchainImages(ref GpuDevice gpu)
	{
		uint32_t swap_chain_count = 0;
		auto result = vkGetSwapchainImagesKHR(gpu.device, mSwapchain, &swap_chain_count, null);
		if (result != VK_SUCCESS)
		{
			writeln("Error : vkGetSwapchainImagesKHR() failed.");
			return false;
		}
		return true;
	}

	void finalize()
	{
		version(Vulkan)
		{
			vkDestroySwapchainKHR(mHostDevice, mSwapchain, null);
		}
	}

private:
	version(Vulkan)
	{
		VkDevice		mHostDevice;
		VkSurfaceKHR	mSurface;
		VkSwapchainKHR	mSwapchain;
	}
}
