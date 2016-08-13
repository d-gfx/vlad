/**
 *	image.d
 *
 *	Vulkan image
 */
module vlad.gpu.vulkan.image;

private
{
	import std.conv;
}

version(Vulkan) {
	import vlad.basis;
	import vlad.gpu.vulkan;

	void clearColorImage(VkImage image, VkCommandBuffer cmd, in C4f color)
	{
		VkClearColorValue clearColor;
		clearColor.float32[0] = color.r;
		clearColor.float32[1] = color.g;
		clearColor.float32[2] = color.b;
		clearColor.float32[3] = color.a;
		
		VkImageSubresourceRange range;
		range.aspectMask     = VK_IMAGE_ASPECT_COLOR_BIT;
		range.baseMipLevel   = 0;
		range.levelCount     = 1;
		range.baseArrayLayer = 0;
		range.layerCount     = 1;
		
		vkCmdClearColorImage(cmd
							 , image
							 , VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
							 , &clearColor
							 , 1
							 , &range);
	}

	void setImageLayout(VkImage image
						, VkCommandBuffer cmd
						, VkImageAspectFlags aspect_flag
						, VkImageLayout old_layout
						, VkImageLayout new_layout
						)
	{
		VkImageMemoryBarrier barrier;
		barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
		barrier.pNext = null;
		barrier.srcAccessMask = 0;
		barrier.dstAccessMask = 0;
		barrier.oldLayout = old_layout;
		barrier.newLayout = new_layout;
		barrier.image = image;
		barrier.subresourceRange = VkImageSubresourceRange(aspect_flag, 0, 1, 0, 1);
		switch(old_layout)
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
	}
}
