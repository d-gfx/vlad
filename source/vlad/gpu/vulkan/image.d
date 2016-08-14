/**
 *	image.d
 *
 *	Vulkan image
 */
module vlad.gpu.vulkan.image;

private
{
	import std.stdio;
	import std.conv;
	import std.typecons;
	import vlad.gpu.device;
	import vlad.gpu.texture.image;
	import vlad.gpu.texture.format;
}

version(Vulkan) {
	import vlad.basis;
	import vlad.gpu.vulkan;

	VkImageViewType getVkImageViewType(in TexType type) @nogc nothrow pure
	{
		switch (type)
		{
		case TexType.Tex1D:				return VK_IMAGE_VIEW_TYPE_1D;
		case TexType.Tex1DArray:		return VK_IMAGE_VIEW_TYPE_1D_ARRAY;
		case TexType.Tex2D:				return VK_IMAGE_VIEW_TYPE_2D;
		case TexType.Tex2DArray:		return VK_IMAGE_VIEW_TYPE_2D_ARRAY;
		case TexType.Tex3D:				return VK_IMAGE_VIEW_TYPE_3D;
		case TexType.TexCubeMap:		return VK_IMAGE_VIEW_TYPE_CUBE;
		case TexType.TexCubeMapArray:	return VK_IMAGE_VIEW_TYPE_CUBE_ARRAY;
		default:	assert(0);
		}
	}

	VkImageType getVkImageType(in TexType type) @nogc nothrow pure
	{
		switch (type)
		{
		case TexType.Tex1D:				return VK_IMAGE_TYPE_1D;
		case TexType.Tex1DArray:		return VK_IMAGE_TYPE_1D;
		case TexType.Tex2D:				return VK_IMAGE_TYPE_2D;
		case TexType.Tex2DArray:		return VK_IMAGE_TYPE_2D;
		case TexType.Tex3D:				return VK_IMAGE_TYPE_3D;
		case TexType.TexCubeMap:		return VK_IMAGE_TYPE_2D;
		case TexType.TexCubeMapArray:	return VK_IMAGE_TYPE_2D;
		default:	assert(0);
		}
	}
	void clearColorImage(VkImage image, VkCommandBuffer cmd, in C4f color)
	{
		VkClearColorValue clear_color;
		clear_color.float32[0] = color.r;
		clear_color.float32[1] = color.g;
		clear_color.float32[2] = color.b;
		clear_color.float32[3] = color.a;
		
		VkImageSubresourceRange range;
		range.aspectMask     = VK_IMAGE_ASPECT_COLOR_BIT;
		range.baseMipLevel   = 0;
		range.levelCount     = 1;
		range.baseArrayLayer = 0;
		range.layerCount     = 1;
		
		vkCmdClearColorImage(cmd
							 , image
							 , VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
							 , &clear_color
							 , 1
							 , &range);
	}

	void clearDepthStencilImage(VkImage image, VkCommandBuffer cmd, f32 clear_depth, u32 clear_stencil = 0)
	{
		VkClearDepthStencilValue clear_value;
		clear_value.depth   = clear_depth;
		clear_value.stencil = clear_stencil;
		
		VkImageSubresourceRange range;
		range.aspectMask     = VK_IMAGE_ASPECT_DEPTH_BIT | VK_IMAGE_ASPECT_STENCIL_BIT;
		range.baseMipLevel   = 0;
		range.levelCount     = 1;
		range.baseArrayLayer = 0;
		range.layerCount     = 1;
		
		vkCmdClearDepthStencilImage(
					cmd
					, image
					, VK_IMAGE_LAYOUT_GENERAL
					, &clear_value
					, 1
					, &range);
	}

	void setImageLayout(VkImage image
						, VkCommandBuffer cmd
						, VkImageAspectFlags aspect_flag
						, VkImageLayout* layout_ptr
						, VkImageLayout new_layout
						)
	{
		VkImageMemoryBarrier barrier;
		barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
		barrier.pNext = null;
		barrier.srcAccessMask = 0;
		barrier.dstAccessMask = 0;
		barrier.oldLayout = *layout_ptr;
		barrier.newLayout = new_layout;
		barrier.image = image;
		barrier.subresourceRange = VkImageSubresourceRange(aspect_flag, 0, 1, 0, 1);
		switch(*layout_ptr)
		{
		case VK_IMAGE_LAYOUT_UNDEFINED:
			barrier.srcAccessMask = 0;
			break;
		case VK_IMAGE_LAYOUT_PREINITIALIZED:
			barrier.srcAccessMask = VK_ACCESS_HOST_WRITE_BIT;
			break;
		case VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL:
			barrier.srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
			break;
		case VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL:
			barrier.srcAccessMask = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;
			break;
		case VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL:
			barrier.srcAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
			break;
		case VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL:
			barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
			break;
		case VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL:
			barrier.srcAccessMask = VK_ACCESS_SHADER_READ_BIT;
			break;
		default:
//			writeln("old_layout = " ~ to!string(old_layout));
			break;
		}
		switch (new_layout)
		{
		case VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL:
			barrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
			break;
		case VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL:
			barrier.srcAccessMask |= VK_ACCESS_TRANSFER_READ_BIT;
			barrier.dstAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
			break;
		case VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL:
			barrier.srcAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
			barrier.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
			break;
		case VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL:
			barrier.dstAccessMask = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;
			break;
		case VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL:
			if (barrier.srcAccessMask == 0)
			{
				barrier.srcAccessMask = VK_ACCESS_HOST_WRITE_BIT | VK_ACCESS_TRANSFER_WRITE_BIT;
			}
			barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;
			break;
		default:
//			writeln("new_layout = " ~ to!string(new_layout));
			break;
		}

		vkCmdPipelineBarrier(cmd
							 , VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT
							 , VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT
							 , 0, 0, null, 0, null, 1, &barrier);
		// update layout
		*layout_ptr = new_layout;
	}

	Tuple!(bool, "is_success", VkImage, "image", VkDeviceMemory, "memory")
		createImage(ref GpuDevice gpu, in TexBuilder builder)
	{
		auto device = gpu.mDevice.device;
		auto memory_props = gpu.mDevice.memory;
		auto physical_device = gpu.mDevice.physical_device;
		auto vk_fmt = cast(VkFormat)builder.ImageFormat;

		VkFormatProperties	fmt_props;
		vkGetPhysicalDeviceFormatProperties(physical_device, vk_fmt, &fmt_props);

		VkFormatFeatureFlagBits flag_bit = VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT;
		VkImageUsageFlagBits usage_bit = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
		if (builder.ImageFormat.isDepthStencil())
		{
			flag_bit = VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT;
			usage_bit = VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
		}

		VkImageTiling		img_tiling;
		if (fmt_props.linearTilingFeatures & flag_bit)
		{
			img_tiling = VK_IMAGE_TILING_LINEAR;
		}
		else if (fmt_props.optimalTilingFeatures & flag_bit)
		{
			img_tiling = VK_IMAGE_TILING_OPTIMAL;
		}
		else
		{
			writeln("Error : createImage failed. : VkImageTiling not supported Format[%s]", builder.ImageFormat.stringof);
			return typeof(return)(false, VK_NULL_ND_HANDLE, VK_NULL_ND_HANDLE);
		}
		writeln("VkImageTiling = %s", img_tiling.stringof);

		VkImageCreateInfo create_info;
		with (create_info)
		{
			pNext					= null;
			flags					= 0;
			imageType				= getVkImageType(builder.TextureType);
			format					= vk_fmt;
			extent.width			= builder.Width;
			extent.height			= builder.Height;
			extent.depth			= builder.Depth;
			mipLevels				= builder.CountMipLevel;
			arrayLayers				= builder.CountArrayLayer; // @fixme cubemap
			samples					= VK_SAMPLE_COUNT_1_BIT;
			tiling					= img_tiling;
			usage					= usage_bit;
			sharingMode				= VK_SHARING_MODE_EXCLUSIVE;
			queueFamilyIndexCount	= 0;
			pQueueFamilyIndices		= null;
			initialLayout			= VK_IMAGE_LAYOUT_UNDEFINED;
		}
		VkImage image;
		auto result = vkCreateImage(device, &create_info, null, &image);
		if (result != VK_SUCCESS)
		{
		    writeln("Error : vkCreateImage() Failed.");
			return typeof(return)(false, VK_NULL_ND_HANDLE, VK_NULL_ND_HANDLE);
		}

		// memory allocate
		VkDeviceMemory memory;

		VkMemoryRequirements mem_req;
		vkGetImageMemoryRequirements(device, image, &mem_req);

		VkFlags req_mask = 0;
		uint32_t typeBits  = mem_req.memoryTypeBits;
		uint32_t typeIndex = 0;
		foreach (int i; 0..VK_MAX_MEMORY_TYPES)
		{
			if ((typeBits & 0x1) == 1)
			{
				if ((memory_props.memoryTypes[i].propertyFlags & req_mask) == req_mask)
				{
					typeIndex = i;
					break;
				}
			}
			typeBits >>= 1;
		}

		VkMemoryAllocateInfo alloc_info;
		with (alloc_info)
		{
			pNext				= null;
			allocationSize		= mem_req.size;
			memoryTypeIndex		= typeIndex;
		}

		result = vkAllocateMemory(device, &alloc_info, null, &memory);
		if (result != VK_SUCCESS)
		{
			writeln("Error : vkAllocateMemory() Failed.");
			return typeof(return)(false, VK_NULL_ND_HANDLE, VK_NULL_ND_HANDLE);
		}

		result = vkBindImageMemory(device, image, memory, 0);
		if (result != VK_SUCCESS)
		{
			writeln("Error : vkBindImageMemory() Failed.");
			return typeof(return)(false, VK_NULL_ND_HANDLE, VK_NULL_ND_HANDLE);
		}


		return typeof(return)(true, image, memory);
	}
}
