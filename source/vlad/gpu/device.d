/*
	device.d
*/
module vlad.gpu.device;

import std.stdio;
import vlad.basis;
import vlad.gpu.commandbuffer;

version(Vulkan)
{
	import vlad.gpu.vulkan;
	alias	Instance = VkInstance;
}


struct GpuDevice
{
	version(Vulkan)
	{
		VulkanDevice	mDevice;
	}

	CommandBuffer	mCommandBuffer;

	void finalize()
	{
		if (mCommandBuffer !is null)
		{
			mCommandBuffer.finalize();
			mCommandBuffer = null;
		}
		version(Vulkan)
		{
			mDevice.finalize();
		}
	}
}

bool setupApi()
{
	version(Vulkan)
	{
		return setupVulkanApi();
	}
	else
	{
		return false;
	}
}

bool createInstance(ref Instance inst, string app_namez, int app_ver_major, int app_ver_minor, int app_ver_patch)
{
	version(Vulkan)
	{
		return createInstanceVulkan(inst, app_namez, app_ver_major, app_ver_minor, app_ver_patch);
	}
	else
	{
		return false;
	}
}

bool enumerateDevices(ref Instance inst, ref GpuDevice[] devices)
{
	version(Vulkan)	{ return enumerateDevicesVulkan(inst, devices); }
	else			{ return false; }
}

bool createDevices(ref GpuDevice[] devices)
{
	version(Vulkan)	{ return createDevicesVulkan(devices); }
	else			{ return true; }
}

