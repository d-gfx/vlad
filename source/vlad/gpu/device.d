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
		auto result = vkEnumeratePhysicalDevices(inst, &count, null);
		if (result != VkResult.VK_SUCCESS || count < 1)
		{
			writeln("Error : vkEnumeratePhysicalDevices() Failed.");
			return false;
		}

		devices.length = count;

		VkPhysicalDevice[] tmp_devs;
		tmp_devs.length = count;
		scope (exit) tmp_devs.length = 0;

		result = vkEnumeratePhysicalDevices(inst, &count, tmp_devs.ptr);
		if (result != VkResult.VK_SUCCESS)
		{
			writeln("Error : vkEnumeratePhysicalDevices() Failed.");
			return false;
		}

		foreach(i, dev; tmp_devs)
		{
			devices[i].device = dev;
			vkGetPhysicalDeviceMemoryProperties(devices[i].device, &devices[i].memory);
		}

		// enumerate queue property
		foreach (ref dev; devices)
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
				if (dev.queue_family_props[i].queueFlags & VkQueueFlagBits.VK_QUEUE_GRAPHICS_BIT)
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
	}

	void finalize()
	{
		if (!mIsEnable)
			return;

		vkDestroyInstance(mInstance, null);
		writeln("GpuDevice::finalize.");
	}
	bool isEnable() const { return mIsEnable; }
private:
	bool				mIsEnable;
	Instance			mInstance;
	PhysicalDevice[]	mDevices;
}
