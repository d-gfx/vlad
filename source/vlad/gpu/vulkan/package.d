/**
 *	vulkan.d
 */
module vlad.gpu.vulkan;

import vlad.basis;

version(Vulkan)
{
	version = VulkanErupted;
}

version(VulkanErupted)
{
	public import erupted;
}

version(Vulkan)
{
	public import vlad.gpu.vulkan.device;

	enum VK_API_VERSION = VK_MAKE_VERSION(1, 0, 3);

	version(X86_64) {
		bool isHandleNull(Handle)(Handle h) { return h is null; }
		auto getHandleNull() { return null; }
	} else {
		bool isHandleNull(Handle)(Handle h) { return h == 0; }
		auto getHandleNull() { return 0; }
	}

	bool setupVulkanApi()
	{
		version(VulkanErupted)
		{
			DerelictErupted.load();
			return DerelictErupted.isLoaded();
		}
	}

	void loadVulkanFunctions(VkInstance inst)
	{
		version(VulkanErupted)
		{
			loadInstanceLevelFunctions(inst);
			loadDeviceLevelFunctions(inst);
		}
	}

	bool createInstanceVulkan(ref VkInstance inst, string app_namez, int app_ver_major, int app_ver_minor, int app_ver_patch)
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

		// load functions
		loadVulkanFunctions(inst);

		return (ret == VkResult.VK_SUCCESS);
	}
}
