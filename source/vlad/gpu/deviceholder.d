/**
 *	deviceholder.d
 */
module vlad.gpu.deviceholder;

import vlad.basis;
import vlad.gpu.device;
import vlad.gpu.commandbuffer;
import vlad.gpu.swapchain;
import std.stdio;

version(Windows)
{
	import core.sys.windows.windows;
}

version(Vulkan)
{
	import dvulkan;
}

struct GpuInitArg
{
	version(Windows)
	{
		HINSTANCE h_inst;
		HWND hwnd;
	}
}

/**
 *	Gpu Device Holder class
 */
class GpuDeviceHolder
{
public:
	this (ref GpuInitArg arg)
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

		version(Windows)
		{
			// window size
			RECT rect;
			GetClientRect(arg.hwnd, &rect);
			int width  = rect.right - rect.left;
			int height = rect.bottom - rect.top;

			mSwapChain = new SwapChain();
			mIsEnable = mSwapChain.createSurface(mInstance, arg.h_inst, arg.hwnd);
			if (!mIsEnable)
			{
				finalize();
				writeln("Error : SwapChain.createSurface (Windows) failed.");
				return;
			}
		}

		mIsEnable = mSwapChain.createSwapchain(mGpuDevices[0], width, height);
		if (!mIsEnable)
		{
			finalize();
			writeln("Error : SwapChain.createSwapchain failed.");
			return;
		}

		writeln("GpuDevice::created.");
		printInfo();
	}

	void finalize()
	{
		if (mSwapChain !is null)
			mSwapChain.finalize();

		foreach (int i, ref dev; mGpuDevices)
		{
			dev.finalize();
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
	SwapChain			mSwapChain;
}
