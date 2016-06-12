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
