/*
	device.d
*/
module vlad.gpu.device;

import std.stdio;
import vlad.basis;

version(Vulkan)
{
	import dvulkan;
	alias	Instance = VkInstance;

	enum VK_API_VERSION = VK_MAKE_VERSION(1, 0, 3);

	version(X86_64) {
		bool isHandleNull(Handle)(Handle h) { return h is null; }
	} else {
		bool isHandleNull(Handle)(Handle h) { return h == 0; }
	}

	struct GpuDevice
	{
		VkDevice							device;
		VkQueue								gfx_queue;
		VkPhysicalDevice					physical_device;
		VkPhysicalDeviceMemoryProperties	memory;
		VkPhysicalDeviceProperties			device_props;
		VkCommandPool						command_pool;
		int									gfx_queue_index;
		VkQueueFamilyProperties[]			queue_family_props;
	}

	bool setupApi()
	{
		DVulkanDerelict.load();
		return DVulkanDerelict.isLoaded();
	}

	bool createInstance(ref Instance inst, string app_namez, int app_ver_major, int app_ver_minor, int app_ver_patch)
	{
		VkApplicationInfo app_info;
		with (app_info)
		{
			sType = VkStructureType.VK_STRUCTURE_TYPE_APPLICATION_INFO;
			pNext = null;
			applicationVersion = VK_MAKE_VERSION(app_ver_major, app_ver_minor, app_ver_patch);
			pApplicationName = app_namez.ptr;
			pEngineName = "vlad\0".ptr;
			engineVersion = VK_MAKE_VERSION(LibraryVersion.Major, LibraryVersion.Minor, LibraryVersion.Patch);
			apiVersion = VK_API_VERSION;
		}

		const(char)*[2] extensions;
		version(none)
		{
			extensions[0] = VK_KHR_SURFACE_EXTENSION_NAME.ptr;
			extensions[1] = VK_KHR_WIN32_SURFACE_EXTENSION_NAME.ptr;
		}

		VkInstanceCreateInfo instance_info;
		with (instance_info)
		{
			sType = VkStructureType.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
			pApplicationInfo = &app_info;
			pNext = null;
			flags = 0;
			enabledLayerCount = 0;
			ppEnabledLayerNames = null;
			version(none)
			{
				enabledExtensionCount = extensions.length;
				ppEnabledExtensionNames = extensions.ptr;
			}
			else
			{
				enabledExtensionCount = 0;
				ppEnabledExtensionNames = null;
			}
		}

		auto ret = vkCreateInstance(&instance_info, null, &inst);

		// inst を使ってその他の関数を全てロードするようだ
		DVulkanLoader.loadAllFunctions(inst);

		return (ret == VkResult.VK_SUCCESS);
	}
	bool enumerateDevices(ref Instance inst, ref GpuDevice[] devices)
	{
		uint count = 0;
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
			dev.physical_device = tmp_devs[i];
			// memory props
			vkGetPhysicalDeviceMemoryProperties(dev.physical_device, &dev.memory);
			// device props
			vkGetPhysicalDeviceProperties(dev.physical_device, &dev.device_props);
		}

		// enumerate queue property
		foreach (int d, ref dev; devices)
		{
			// get queue family count
			uint prop_count;
			vkGetPhysicalDeviceQueueFamilyProperties(dev.physical_device, &prop_count, null);

			// allocate buffer
			dev.queue_family_props.length = prop_count;

			// store queue family property
			vkGetPhysicalDeviceQueueFamilyProperties(dev.physical_device, &prop_count, dev.queue_family_props.ptr);

			// find graphics queue
			foreach(i; 0..prop_count)
			{
				auto flags = dev.queue_family_props[i].queueFlags;
				if (flags & VkQueueFlagBits.VK_QUEUE_GRAPHICS_BIT)
				{
					dev.gfx_queue_index = i;
				}
			}
		}

		return true;
	}

	bool createDevices(ref GpuDevice[] devices)
	{
		foreach (ref dev; devices)
		{
			VkDeviceQueueCreateInfo queue_info;
			float[] priorities = [ 0.0f ];
			with (queue_info)
			{
				sType	= VkStructureType.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
				pNext	= null;
				queueCount	= priorities.length;
				queueFamilyIndex = dev.gfx_queue_index;
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
		
			auto result = vkCreateDevice(dev.physical_device, &device_info, null, &dev.device);

			if (result != VkResult.VK_SUCCESS)
			{
				writeln( "Error : vkCreateDevice() Failed." );
				return false;
			}
			writefln("dev.device = %s", dev.device);
			vkGetDeviceQueue(dev.device, dev.gfx_queue_index, 0, &dev.gfx_queue);

			// command pool
			VkCommandPoolCreateInfo cp_info;
			with (cp_info)
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
				pNext              = null;
				queueFamilyIndex   = dev.gfx_queue_index;
				flags = VkCommandPoolCreateFlagBits.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
			}
			writefln( "vkCreateCommandPool = %s", vkCreateCommandPool);
			result = vkCreateCommandPool(dev.device, &cp_info, null, &dev.command_pool);
			if (result != VkResult.VK_SUCCESS)
			{
				writeln( "Error : vkCreateCommandPool() Failed." );
				return false;
			}
			/*
			writefln( "Create and Destroy!!  vkDestroyCommandPool = %s", vkDestroyCommandPool);
			vkDestroyCommandPool(dev.device, dev.command_pool, null);
			writeln( "Destroy!!" );
			*/
		}
		return true;
	}
}

/**
 *	Gpu Device class
 */
class GpuDevices
{
public:
	this ()
	{
		mIsEnable = setupApi();
		if (!mIsEnable)
			return;

		mIsEnable = createInstance(mInstance, "vlad_app\0", 0, 1, 0);
		if (!mIsEnable)
			return;

		mIsEnable = enumerateDevices(mInstance, mGpuDevices);
		if (!mIsEnable)
		{
			finalize();
			writeln("Error : GpuDevice::enumerateDevices failed.");
			return;
		}

		mIsEnable = createDevices(mGpuDevices);
		if (!mIsEnable)
		{
			finalize();
			writeln("Error : GpuDevice::createDevices failed.");
			return;
		}

		writeln("GpuDevice::created.");
		printInfo();
	}

	void finalize()
	{
		if (!mIsEnable)
			return;

		writefln("mGpuDevices.length = %s", mGpuDevices.length);
		foreach (int i, ref dev; mGpuDevices)
		{
			writefln("mGpuDevices[%s].device = %s", i, dev.device);
			if (dev.device is null)
				continue;

			writefln("vkDestroyCommandPool = %s", vkDestroyCommandPool);
			if (!isHandleNull(dev.command_pool))
				vkDestroyCommandPool(dev.device, dev.command_pool, null);
			vkDestroyDevice(dev.device, null);
		}
		vkDestroyInstance(mInstance, null);
		writeln("GpuDevice::finalize.");
	}
	nothrow bool isEnable() const { return mIsEnable; }
	nothrow ref GpuDevice getGpuDevice(int i) { return mGpuDevices[i]; }
	nothrow ref const(GpuDevice) getGpuDevice(int i) const { return mGpuDevices[i]; }

	void printInfo() const
	{
		// get properties
		foreach(d, ref dev; mGpuDevices)
		{
			writefln("deviceName = %s", dev.device_props.deviceName);
			writefln("\tdevice[%s] prop_count = %s", d, dev.queue_family_props.length);

			foreach(p; 0..dev.queue_family_props.length)
			{
				auto flags = dev.queue_family_props[p].queueFlags;
				if (flags & VkQueueFlagBits.VK_QUEUE_GRAPHICS_BIT)
				{
					writefln("\t\tdevice[%s].prop[%s] = Graphics", d, p);
				}
				if (flags & VkQueueFlagBits.VK_QUEUE_COMPUTE_BIT)
				{
					writefln("\t\tdevice[%s].prop[%s] = Compute", d, p);
				}
				if (flags & VkQueueFlagBits.VK_QUEUE_TRANSFER_BIT)
				{
					writefln("\t\tdevice[%s].prop[%s] = Transfer", d, p);
				}
				if (flags & VkQueueFlagBits.VK_QUEUE_SPARSE_BINDING_BIT)
				{
					writefln("\t\tdevice[%s].prop[%s] = SparseBinding", d, p);
				}
			}
		}
	}
private:
	bool				mIsEnable;
	Instance			mInstance;
	GpuDevice[]			mGpuDevices;
}
