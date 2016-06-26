/*
 *	device.d
 */
module vlad.gpu.vulkan.device;

import vlad.gpu.device;

version(Vulkan)
{
	import vlad.gpu.vulkan;
	import vlad.basis;
	import std.stdio;

	struct VulkanDevice
	{
		VkDevice							device;
		VkQueue								gfx_queue;
		VkPhysicalDevice					physical_device;
		VkPhysicalDeviceMemoryProperties	memory;
		VkPhysicalDeviceProperties			device_props;
		VkCommandPool						command_pool;
		int									gfx_queue_index;
		VkQueueFamilyProperties[]			queue_family_props;

		void finalize()
		{
			if (device is null) return;
			if (!isHandleNull(command_pool))
			{
				vkDestroyCommandPool(device, command_pool, null);
			}
			vkDestroyDevice(device, null);
		}
	}

	bool enumerateDevicesVulkan(ref VkInstance inst, ref GpuDevice[] devices)
	{
		uint count = 0;
		assert(vkEnumeratePhysicalDevices !is null);
		// count physical device
		auto result = vkEnumeratePhysicalDevices(inst, &count, null);
		if (result != VkResult.VK_SUCCESS || count < 1)
		{
			writeln("Error : vkEnumeratePhysicalDevices() Failed.");
			return false;
		}

		devices.length = count;

		VkPhysicalDevice[] tmp_devs;
		tmp_devs.length = count;

		// store physical device
		result = vkEnumeratePhysicalDevices(inst, &count, tmp_devs.ptr);

		if (result != VkResult.VK_SUCCESS)
		{
			writeln("Error : vkEnumeratePhysicalDevices() Failed.");
			return false;
		}

		// get properties
		foreach(i, ref dev; devices)
		{
			with (dev.mDevice)
			{
				physical_device = tmp_devs[i];
				// memory props
				vkGetPhysicalDeviceMemoryProperties(physical_device, &memory);
				// device props
				vkGetPhysicalDeviceProperties(physical_device, &device_props);
			}
		}

		// enumerate queue property
		foreach (int d, ref dev; devices)
		{
			with (dev.mDevice)
			{
				// get queue family count
				uint prop_count;
				vkGetPhysicalDeviceQueueFamilyProperties(physical_device, &prop_count, null);

				// allocate buffer
				queue_family_props.length = prop_count;

				// store queue family property
				vkGetPhysicalDeviceQueueFamilyProperties(physical_device, &prop_count, queue_family_props.ptr);

				// find graphics queue
				foreach(i; 0..prop_count)
				{
					auto flags = queue_family_props[i].queueFlags;
					if (flags & VkQueueFlagBits.VK_QUEUE_GRAPHICS_BIT)
					{
						gfx_queue_index = i;
					}
				}
			}
		}
		return true;
	}

	bool createDevicesVulkan(ref GpuDevice[] devices)
	{
		foreach (ref dev; devices){with (dev.mDevice)
		{
			VkDeviceQueueCreateInfo queue_info;
			float[] priorities = [ 0.0f ];
			with (queue_info)
			{
				sType	= VkStructureType.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
				pNext	= null;
				queueCount	= priorities.length;
				queueFamilyIndex = gfx_queue_index;
				pQueuePriorities = priorities.ptr;
			}

			VkDeviceCreateInfo device_info;
			with (device_info)
			{
				sType	= VkStructureType.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
				pNext					= null;
				queueCreateInfoCount	= 1;
				pQueueCreateInfos		= &queue_info;
				enabledLayerCount		= 0;
				ppEnabledLayerNames		= null;
				enabledExtensionCount	= 0;
				ppEnabledExtensionNames	= null;
				pEnabledFeatures		= null;
			}

			auto result = vkCreateDevice(physical_device, &device_info, null, &device);

			if (result != VkResult.VK_SUCCESS)
			{
				writeln( "Error : vkCreateDevice() Failed." );
				return false;
			}
			vkGetDeviceQueue(device, gfx_queue_index, 0, &gfx_queue);

			// command pool
			VkCommandPoolCreateInfo cp_info;
			with (cp_info)
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
				pNext              = null;
				queueFamilyIndex   = gfx_queue_index;
				flags = VkCommandPoolCreateFlagBits.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
			}
			result = vkCreateCommandPool(device, &cp_info, null, &command_pool);
			if (result != VkResult.VK_SUCCESS)
			{
				writeln( "Error : vkCreateCommandPool() Failed." );
				return false;
			}
		}}
		return true;
	}
} // Vulkan
