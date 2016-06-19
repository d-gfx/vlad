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

class Texture
{
	enum TexType
	{
		Tex1D, Tex1DArray, Tex2D, Tex2DArray, Tex3D, TexCubeMap, TexCubeMapArray
	}

	struct Builder
	{
		alias Self = Builder;
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
			mixin(DefineBuilderMember!("VkImageLayout", "ImageLayout", "VK_IMAGE_LAYOUT_UNDEFINED"));
			mixin(DefineBuilderMember!("VkImage", "Image",	"VK_NULL_ND_HANDLE")); // if already created
		}
	}

	/**
	 *	create texture by builder
	 */
	bool create(ref GpuDevice gpu, ref Builder builder)
	{
		version(Vulkan)
		{
			if (builder.ImageLayout == VK_IMAGE_LAYOUT_UNDEFINED)
			{
				vlAssert(0, "builder.ImageLayout = %s", builder.ImageLayout);
				return false;
			}
			if (builder.Image !is VK_NULL_ND_HANDLE)
			{
				mImage = builder.Image;
			}
			else
			{
				// create image
			}
			// create image view
			VkImageViewCreateInfo view_info;
			view_info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
			view_info.pNext = null;
			view_info.flags = 0;
			view_info.image = mImage;
			switch (builder.TextureType)
			{
			case TexType.Tex1D:				view_info.viewType = VK_IMAGE_VIEW_TYPE_1D;			break;
			case TexType.Tex1DArray:		view_info.viewType = VK_IMAGE_VIEW_TYPE_1D_ARRAY;	break;
			case TexType.Tex2D:				view_info.viewType = VK_IMAGE_VIEW_TYPE_2D;			break;
			case TexType.Tex2DArray:		view_info.viewType = VK_IMAGE_VIEW_TYPE_2D_ARRAY;	break;
			case TexType.Tex3D:				view_info.viewType = VK_IMAGE_VIEW_TYPE_3D;			break;
			case TexType.TexCubeMap:		view_info.viewType = VK_IMAGE_VIEW_TYPE_CUBE;		break;
			case TexType.TexCubeMapArray:	view_info.viewType = VK_IMAGE_VIEW_TYPE_CUBE_ARRAY;	break;
			default:	assert(0);
			}
			view_info.format = builder.ImageFormat;
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

			auto result = vkCreateImageView(gpu.device, &view_info, null, &mView);
			if (result != VK_SUCCESS)
			{
				import std.stdio;
				writeln("Error : vkCreateImageView() failed.");
				return false;
			}
		}
		mHost = &gpu;
		return true;
	}

	void finalize()
	{
	}
private:
	GpuDevice*	mHost;
	version(Vulkan)
	{
		VkImage		mImage;
		VkImageView	mView;
	}
}
