/**
 *	vulkan.d
 */
module vlad.gpu.vulkan;

version(Vulkan)
{
	version = VulkanErupted;

	version(VulkanErupted)
	{
		public import erupted;
	}

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
}
