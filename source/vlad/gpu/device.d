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
	bool		mIsEnable;
	Instance	mInstance;
}
