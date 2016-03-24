/*
	device.d
*/
module vlad.gpu.device;

import std.stdio;
import vlad.basis;

version(Vulkan)
{
	private import derelict.vulkan.vk;
	private import derelict.vulkan.vulkan;
	alias	Instance = VkInstance;

	struct PhysicalDevice
	{
		VkPhysicalDevice					device;
		VkPhysicalDeviceMemoryProperties	memory;
		VkPhysicalDeviceProperties			device_props;
		int									graphics_queue_index;
		VkQueueFamilyProperties[]			queue_family_props;
	}

	bool setupApi()
	{
		DerelictVulkan.load();
		return DerelictVulkan.isLoaded();
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
		version(Windows)
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
			version(Windows)
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
		return (ret == VkResult.VK_SUCCESS);
	}
	bool enumerateDevices(ref Instance inst, ref PhysicalDevice[] devices)
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
			dev.device = tmp_devs[i];
			// memory props
			vkGetPhysicalDeviceMemoryProperties(dev.device, &dev.memory);
			// device props
			vkGetPhysicalDeviceProperties(dev.device, &dev.device_props);
		}

		// enumerate queue property
		foreach (int d, ref dev; devices)
		{
			// get queue family count
			uint prop_count;
			vkGetPhysicalDeviceQueueFamilyProperties(dev.device, &prop_count, null);

			// allocate buffer
			dev.queue_family_props.length = prop_count;

			// store queue family property
			vkGetPhysicalDeviceQueueFamilyProperties(dev.device, &prop_count, dev.queue_family_props.ptr);

			// find graphics queue
			foreach(i; 0..prop_count)
			{
				auto flags = dev.queue_family_props[i].queueFlags;
				if (flags & VkQueueFlagBits.VK_QUEUE_GRAPHICS_BIT)
				{
					dev.graphics_queue_index = i;
				}
			}
		}

		return true;
	}
}

/**
 *	Gpu Device class
 */
class GpuDevice
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

		mIsEnable = enumerateDevices(mInstance, mDevices);
		if (!mIsEnable)
		{
			finalize();
			writeln("Error : GpuDevice::enumerateDevices failed.");
			return;
		}

		writeln("GpuDevice::created.");
		printInfo();
	}

	void finalize()
	{
		if (!mIsEnable)
			return;

		vkDestroyInstance(mInstance, null);
		writeln("GpuDevice::finalize.");
	}
	nothrow bool isEnable() const { return mIsEnable; }

	void printInfo() const
	{
		// get properties
		foreach(d, ref dev; mDevices)
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
	PhysicalDevice[]	mDevices;
}
