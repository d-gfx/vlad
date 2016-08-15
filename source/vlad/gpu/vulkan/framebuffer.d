/**
 *	framebuffer.d
 *
 *	Vulkan framebuffer
 */
module vlad.gpu.vulkan.framebuffer;

version(Vulkan){

alias VkFramebufferUtil = vlad.gpu.vulkan.framebuffer;
import vlad.basis;
import vlad.gpu.vulkan;
import std.typecons : Tuple;

Tuple!(bool, "is_success", VkFramebuffer, "framebuffer")
createFramebuffer(VkDevice device
				  , in VkRenderPass render_pass
				  , u32 width
				  , u32 height
				  , const(VkImageView[]) views ...)
{
	vlAssert(0 < views.length);
	VkFramebufferCreateInfo info;
	// All frame buffers use the same renderpass setup
	info.renderPass = render_pass;
	info.attachmentCount = views.length;
	info.pAttachments = views.ptr;
	info.width = width;
	info.height = height;
	info.layers = 1;
	// Create the framebuffer
	VkFramebuffer framebuffer;
	auto ret = vkCreateFramebuffer(device, &info, null, &framebuffer);
	if (ret != VK_SUCCESS)
	{
		return typeof(return)(false, VK_NULL_ND_HANDLE);
	}
	return typeof(return)(true, framebuffer);
}

} // version(Vulkan)
