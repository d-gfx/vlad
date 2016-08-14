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
			auto ret = VkImageUtil.createImage(gpu, builder);
			if (!ret.is_success)
			{
				return false;
			}
			mImage = ret.image;
			mMemory = ret.memory;
			mIsImageOwner = true;
		}

		// aspect flag
		auto aspect_flag = VkImageUtil.decideAspectFlag(builder.ImageFormat);

		// create image view
		auto img_view_ret = VkImageUtil.createImageView(gpu, mImage, aspect_flag, builder);
		if (!img_view_ret.is_success)
		{
			return false;
		}
		mView = img_view_ret.image_view;

		mLayout = VK_IMAGE_LAYOUT_UNDEFINED;

		// set image layout
		VkImageUtil.setImageLayout(mImage
					   , gpu.mCommandBuffer.getCurBuffer()
					   , aspect_flag
					   , &mLayout
					   , VK_IMAGE_LAYOUT_GENERAL);

		// clear texture
		if (builder.ImageFormat.isDepthStencil())
		{
			VkImageUtil.clearDepthStencilImage(mImage, gpu.mCommandBuffer.getCurBuffer(), 1.0f);
		}
		else
		{
			// clear color buffer
			VkImageUtil.clearColorImage(mImage, gpu.mCommandBuffer.getCurBuffer(), C4f.Red);
		}

		// set image layout
		VkImageUtil.setImageLayout(mImage
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
