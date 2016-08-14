/**
 *	deviceholder.d
 */
module vlad.gpu.deviceholder;

import vlad.basis;
import vlad.gpu.device;
import vlad.gpu.commandbuffer;
import vlad.gpu.swapchain;
import vlad.gpu.validation;
import std.stdio;

version(Vulkan)
{
	import vlad.gpu.vulkan;
}

version(Windows)
{
	import core.sys.windows.windows;
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

		mGpuValidation = new GpuValidation(mInstance);

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

		SwapChain.InitArg sw_arg;
		sw_arg.width  = 512;
		sw_arg.height = 512;
		sw_arg.gpu = mGpuDevices[0];
		version(Windows)
		{
			// window size
			RECT rect;
			GetClientRect(arg.hwnd, &rect);
			sw_arg.width  = rect.right - rect.left;
			sw_arg.height = rect.bottom - rect.top;
			sw_arg.inst = mInstance;
			sw_arg.h_inst = arg.h_inst;
			sw_arg.hwnd = arg.hwnd;
		}

		mSwapChain = new SwapChain();
		mIsEnable = mSwapChain.init(sw_arg);
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
		if (mGpuValidation !is null)
			mGpuValidation.finalize();

		foreach (int i, ref dev; mGpuDevices)
		{
			dev.finalize();
		}
		vkDestroyInstance(mInstance, null);
		vlPrintlnInfo("GpuDevice::finalize.");
	}

	nothrow bool isEnable() const { return mIsEnable; }
	nothrow ref GpuDevice getGpuDevice(int i) { return mGpuDevices[i]; }
	nothrow ref const(GpuDevice) getGpuDevice(int i) const { return mGpuDevices[i]; }

	void printInfo() const
	{
		// get properties
		foreach(d, ref dev; mGpuDevices)
		{
			with (dev.mDevice)
			{
				writefln("deviceName = %s", device_props.deviceName);
				writefln("\tdevice[%s] prop_count = %s", d, queue_family_props.length);

				foreach(p; 0..queue_family_props.length)
				{
					auto flags = queue_family_props[p].queueFlags;
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
	}
private:
	bool				mIsEnable;
	Instance			mInstance;
	GpuDevice[]			mGpuDevices;
	SwapChain			mSwapChain;
	GpuValidation		mGpuValidation;
}
