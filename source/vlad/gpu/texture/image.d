/**
 *	image.d
 */
module vlad.gpu.texture.image;

import vlad.basis;
import vlad.gpu.device;
import vlad.gpu.texture.format;

private
{
	// define member variable and getter/setter
	template DefineBuilderMember(string type, string name, string init_value)
	{
		enum DefineBuilderMember = "
			"~type~" m"~name~" = "~init_value~";
			@property "~type~" "~name~"() const { return m"~name~"; }
			Self* set"~name~"(in "~type~" value) { m"~name~" = value; return &this; }
			";
	}
	template DefineBuilderMemberPtr(string type, string name)
	{
		enum DefineBuilderMemberPtr = "
			"~type~"* m"~name~"Ptr = null;
			@property "~type~"* "~name~"Ptr() { return m"~name~"Ptr; }
			Self* set"~name~"Ptr(ref "~type~"* value) { m"~name~"Ptr = value; return &this; }
			";
	}
}

version(Vulkan)
{
	import vlad.gpu.vulkan;
}

enum TexType
{
	Tex1D, Tex1DArray, Tex2D, Tex2DArray, Tex3D, TexCubeMap, TexCubeMapArray
}

struct TexBuilder
{
	alias Self = TexBuilder;
	mixin(DefineBuilderMember!("int", "Width",	"-1"));
	mixin(DefineBuilderMember!("int", "Height",	"-1"));
	mixin(DefineBuilderMember!("int", "Depth",	"-1"));
	mixin(DefineBuilderMember!("int", "Layer",	"-1"));
	mixin(DefineBuilderMember!("int", "BaseMipLevel", "0"));
	mixin(DefineBuilderMember!("int", "CountMipLevel", "1"));
	mixin(DefineBuilderMember!("int", "BaseArrayLayer", "0"));
	mixin(DefineBuilderMember!("int", "CountArrayLayer", "1"));
	mixin(DefineBuilderMember!("TexType", "TextureType", "TexType.Tex2D"));
	mixin(DefineBuilderMember!("ImgFmt", "ImageFormat", "ImgFmt.R8_G8_B8_A8_Unorm"));
	version(Vulkan)
	{
		mixin(DefineBuilderMember!("VkImage", "Image",	"VK_NULL_ND_HANDLE")); // if already created
		mixin(DefineBuilderMember!("VkImageLayout", "ImageLayout", "VK_IMAGE_LAYOUT_UNDEFINED"));
		void setSwapchain(VkImage img, ImgFmt fmt)
		{
			setImage(img);
			setImageLayout(VK_IMAGE_LAYOUT_PRESENT_SRC_KHR);
			setTextureType(TexType.Tex2D);
		}
	}
}

class Texture
{
	/**
	 *	create texture by builder
	 */
	bool create(ref GpuDevice gpu, ref TexBuilder builder) {version(Vulkan){with(gpu.mDevice)
	{
		mHostDevice = gpu.mDevice.device;
		assert(mImage  is VK_NULL_ND_HANDLE);
		assert(mView   is VK_NULL_ND_HANDLE);
		assert(mMemory is VK_NULL_ND_HANDLE);
		if (builder.ImageLayout == VK_IMAGE_LAYOUT_UNDEFINED)
		{
			vlAssert(0, "builder.ImageLayout = %s", builder.ImageLayout);
			return false;
		}
		if (builder.Image !is VK_NULL_ND_HANDLE)
		{
			mImage = builder.Image; // ex. Swapchain image
			mIsImageOwner = false;
		}
		else
		{
			// create image
			auto ret = createImage(gpu, builder);
			if (!ret.is_success)
			{
				return false;
			}
			mImage = ret.image;
			mMemory = ret.memory;
			mIsImageOwner = true;
		}
		// create image view
		VkImageViewCreateInfo view_info;
		view_info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		view_info.pNext = null;
		view_info.flags = 0;
		view_info.image = mImage;
		view_info.viewType = getVkImageViewType(builder.TextureType);
		view_info.format = cast(VkFormat)builder.ImageFormat;
		view_info.components.r	= VK_COMPONENT_SWIZZLE_R;
		view_info.components.g	= VK_COMPONENT_SWIZZLE_G;
		view_info.components.b	= VK_COMPONENT_SWIZZLE_B;
		view_info.components.a	= VK_COMPONENT_SWIZZLE_A;
		view_info.subresourceRange = VkImageSubresourceRange(
										VK_IMAGE_ASPECT_COLOR_BIT
										, builder.BaseMipLevel
										, builder.CountMipLevel
										, builder.BaseArrayLayer
										, builder.CountArrayLayer);

		auto result = vkCreateImageView(device, &view_info, null, &mView);
		if (result != VK_SUCCESS)
		{
			import std.stdio;
			writeln("Error : vkCreateImageView() failed.");
			return false;
		}

		VkImageAspectFlags aspect_flag = VK_IMAGE_ASPECT_COLOR_BIT;
		if (builder.ImageFormat.isDepthStencil())
		{
			aspect_flag = 0;
			if (builder.ImageFormat.isDepth())	 aspect_flag |= VK_IMAGE_ASPECT_DEPTH_BIT;
			if (builder.ImageFormat.isStencil()) aspect_flag |= VK_IMAGE_ASPECT_STENCIL_BIT;
		}

		mLayout = VK_IMAGE_LAYOUT_UNDEFINED;
		// set image layout
		setImageLayout(mImage
					   , gpu.mCommandBuffer.getCurBuffer()
					   , aspect_flag
					   , &mLayout
					   , VK_IMAGE_LAYOUT_GENERAL);

		if (builder.ImageFormat.isDepthStencil())
		{
			clearDepthStencilImage(mImage, gpu.mCommandBuffer.getCurBuffer(), 1.0f);
		}
		else
		{
			// clear color buffer
			clearColorImage(mImage, gpu.mCommandBuffer.getCurBuffer(), C4f.Red);
		}

		// set image layout
		setImageLayout(mImage
					   , gpu.mCommandBuffer.getCurBuffer()
					   , aspect_flag
					   , &mLayout
					   , builder.ImageLayout);
		return true;
	} } } // with, Vulkan

	/**
	 *	Destroy created object
	 */
	void finalize()
	{
		VkDevice device = mHostDevice;
		if (mView !is VK_NULL_ND_HANDLE)
		{
			vkDestroyImageView(device, mView, null);
			mView = VK_NULL_ND_HANDLE;
		}
		if (mMemory !is VK_NULL_ND_HANDLE)
		{
			vkFreeMemory(device, mMemory, null);
			mMemory = VK_NULL_ND_HANDLE;
		}
		if (mImage !is VK_NULL_ND_HANDLE && mIsImageOwner)
		{
			vkDestroyImage(device, mImage, null);
			mImage = VK_NULL_ND_HANDLE;
		}
		vlPrintlnInfo("");
	}

private:
	version(Vulkan)
	{
		VkDevice		mHostDevice;
		VkImage			mImage;
		VkImageView		mView;
		VkImageLayout	mLayout;
		VkDeviceMemory	mMemory; // if needed
	}
	bool	mIsImageOwner = false;
}
