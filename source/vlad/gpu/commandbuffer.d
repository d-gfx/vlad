/**
 *	commandbuffer.d
 */
module vlad.gpu.commandbuffer;

import vlad.basis;
import vlad.gpu.device;
import std.stdio;

version(Vulkan)
{
	import vlad.gpu.vulkan;
}


class CommandBuffer
{
	version(Vulkan)
	{
		VkCommandBuffer[]	mBuffers;
		int					mCurIndex;
		// host info
		VkDevice			mHostDevice;
		VkCommandPool		mHostPool;

		this(){}

		bool isReady() const { return (0 < mBuffers.length); }
		VkCommandBuffer getCurBuffer() { return mBuffers[mCurIndex]; }

		bool create(ref GpuDevice gpu_dev, int swap_chain_cnt)
		{
			with (gpu_dev.mDevice)
			{
				mHostDevice = device;
				mHostPool	= command_pool;
				mBuffers.length = swap_chain_cnt;
		
				VkCommandBufferAllocateInfo info;
				info.sType				= VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
				info.pNext				= null;
				info.commandPool		= command_pool;
				info.level				= VkCommandBufferLevel.VK_COMMAND_BUFFER_LEVEL_PRIMARY;
				info.commandBufferCount	= swap_chain_cnt;
		
				auto result = vkAllocateCommandBuffers(device, &info, mBuffers.ptr);
				if (result != VkResult.VK_SUCCESS)
				{
					writeln("Error : vkAllocateCommandBuffers() Failed.");
					return false;
				}

				return true;
			}
		}

		void finalize()
		{
			if (!isReady()) return;
			vkFreeCommandBuffers(mHostDevice, mHostPool, mBuffers.length, mBuffers.ptr);
		}
	
		bool begin()
		{
			VkCommandBufferInheritanceInfo inheritance_info;
			inheritance_info.sType					= VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO;
			inheritance_info.pNext					= null;
			inheritance_info.renderPass				= getHandleNull();
			inheritance_info.subpass				= 0;
			inheritance_info.framebuffer			= getHandleNull();
			inheritance_info.occlusionQueryEnable	= VK_FALSE;
			inheritance_info.queryFlags				= 0;
			inheritance_info.pipelineStatistics		= 0;
		
			VkCommandBufferBeginInfo begin_info;
			begin_info.sType				= VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
			begin_info.pNext				= null;
			begin_info.flags				= 0;
			begin_info.pInheritanceInfo		= &inheritance_info;
		
			auto result = vkBeginCommandBuffer(getCurBuffer(), &begin_info);
			if (result != VkResult.VK_SUCCESS)
			{
				writeln( "Error : vkBeginCommandBuffer() Failed." );
				return false;
			}
			return true;
		}
	}
}

