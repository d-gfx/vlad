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
	alias	Instance = VkInstance;
	alias	vkUtil = vlad.gpu.vulkan;
	public import vlad.gpu.vulkan.device;
	public import vlad.gpu.vulkan.image;
	public import vlad.gpu.vulkan.framebuffer;
	version(UseVulkanValidation)
	{
		public import vlad.gpu.vulkan.validation;
	}

	enum VK_API_VERSION = VK_MAKE_VERSION(1, 0, 3);

	bool isNdHandleNull(Handle)(Handle h) { return h is VK_NULL_ND_HANDLE; }
	auto getNdHandleNull() { return VK_NULL_ND_HANDLE; }

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

		version(Windows)
		{
			version(UseVulkanValidation)
			{
				const(char)*[] extensions =
				[
					  VK_KHR_SURFACE_EXTENSION_NAME.ptr
					, VK_KHR_WIN32_SURFACE_EXTENSION_NAME.ptr
					, VK_EXT_DEBUG_REPORT_EXTENSION_NAME.ptr
				];
			}
			else
			{
				const(char)*[] extensions =
				[
					  VK_KHR_SURFACE_EXTENSION_NAME.ptr
					, VK_KHR_WIN32_SURFACE_EXTENSION_NAME.ptr
				];
			}
		}
		else
		{
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
