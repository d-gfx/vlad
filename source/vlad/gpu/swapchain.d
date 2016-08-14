/**
*	swapchain.d
*/
module vlad.gpu.swapchain;

import vlad.basis;
import vlad.gpu.commandbuffer;
import vlad.gpu.device;
import vlad.gpu.texture;
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
		version(Vulkan) { with (gpu.mDevice) {
			import vlad.gpu.vulkan.swapchain;
			// create swap chain
			auto ret = createSwapchainVulkan(gpu, &mSwapchain, mSurface, width, height);
			if (!ret.is_success)
			{
				return false;
			}
			uint swap_chain_count = ret.swapchain_count;
			mBackBuffers.length = swap_chain_count;

			// remember host device
			mHostDevice = device;

			// create command buffer per swap chain
			gpu.mCommandBuffer = new CommandBuffer();
			gpu.mCommandBuffer.create(gpu, swap_chain_count);

			// get swapchain images
			VkImage[]	images;
			images.length = swap_chain_count;

			auto result = vkGetSwapchainImagesKHR(device, mSwapchain, &swap_chain_count, images.ptr);
			if (result != VK_SUCCESS)
			{
				writeln("Error : vkGetSwapChainImagesKHR() Failed.");
				return false;
			}

			// create back buffer
			TexBuilder builder;
			builder.setWidth(width).setHeight(height);
			foreach (i; 0..swap_chain_count)
			{
				version(Vulkan)
				{
					builder.setSwapchain(images[i], cast(ImgFmt)ret.fmt);
				}
				else
				{
					static assert(0, "not implemented.");
				}
				mBackBuffers[i] = new Texture();
				mBackBuffers[i].create(gpu, builder);
			}

			images.length = 0;

			// create depth stencil buffer
			TexBuilder depth_builder;
			depth_builder.setWidth(width)
						 .setHeight(height)
						 .setImageFormat(ImgFmt.D32_Sfloat)
						 .setImageLayout(VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
						 .setTextureType(TexType.Tex2D)
				;
			mDepthStencilBuffer = new Texture();
			mDepthStencilBuffer.create(gpu, depth_builder);
		} } // with, Vulkan

		return true;
	}

	/**
	 *	Destory created object
	 */
	void finalize()
	{
		foreach (ref tex; mBackBuffers)
		{
			tex.finalize();
		}
		mDepthStencilBuffer.finalize();
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
	Texture[]	mBackBuffers;
	Texture		mDepthStencilBuffer;
}
