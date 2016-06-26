/**
 *	image.d
 *
 *	Vulkan image
 */
module vlad.gpu.vulkan.image;

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
}
