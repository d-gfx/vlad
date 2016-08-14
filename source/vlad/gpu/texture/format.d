/**
 *	format.d
 */
module vlad.gpu.texture.format;

version(Vulkan)
{
	import vlad.gpu.vulkan;
}

private
{
	template DefineFormatEnum(string vk_type)
	{
		version(Vulkan)
		{
			enum string DefineFormatEnum = vk_type;
		}
	}
}

enum ImgFmt
{
	R4_G4_UnormPack8 =					mixin(DefineFormatEnum!("VK_FORMAT_R4G4_UNORM_PACK8")),
	R4_G4_B4_A4_Pack16_Unorm =			mixin(DefineFormatEnum!("VK_FORMAT_R4G4B4A4_UNORM_PACK16")),
	B4_G4_R4_A4_Pack16_Unorm =			mixin(DefineFormatEnum!("VK_FORMAT_B4G4R4A4_UNORM_PACK16")),
	R5_G6_B5_Pack16_Unorm =				mixin(DefineFormatEnum!("VK_FORMAT_R5G6B5_UNORM_PACK16")),
	B5_G6_R5_Pack16_Unorm =				mixin(DefineFormatEnum!("VK_FORMAT_B5G6R5_UNORM_PACK16")),
	R5_G5_B5_A1_Pack16_Unorm =			mixin(DefineFormatEnum!("VK_FORMAT_R5G5B5A1_UNORM_PACK16")),
	B5_G5_R5_A1_Pack16_Unorm =			mixin(DefineFormatEnum!("VK_FORMAT_B5G5R5A1_UNORM_PACK16")),
	A1_R5_G5_B5_Pack16_Unorm =			mixin(DefineFormatEnum!("VK_FORMAT_A1R5G5B5_UNORM_PACK16")),
	R8_Unorm =							mixin(DefineFormatEnum!("VK_FORMAT_R8_UNORM")),
	R8_Snorm =							mixin(DefineFormatEnum!("VK_FORMAT_R8_SNORM")),
	R8_Uscaled =						mixin(DefineFormatEnum!("VK_FORMAT_R8_USCALED")),
	R8_Sscaled =						mixin(DefineFormatEnum!("VK_FORMAT_R8_SSCALED")),
	R8_Uint =							mixin(DefineFormatEnum!("VK_FORMAT_R8_UINT")),
	R8_Sint =							mixin(DefineFormatEnum!("VK_FORMAT_R8_SINT")),
	R8_Srgb =							mixin(DefineFormatEnum!("VK_FORMAT_R8_SRGB")),
	R8_G8_B8_Unorm =					mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8_UNORM")),
	R8_G8_B8_Snorm =					mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8_SNORM")),
	R8_G8_B8_Uscaled =					mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8_USCALED")),
	R8_G8_B8_Sscaled =					mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8_SSCALED")),
	R8_G8_B8_Uint =						mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8_UINT")),
	R8_G8_B8_Sint =						mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8_SINT")),
	R8_G8_B8_Srgb =						mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8_SRGB")),
	B8_G8_R8_Unorm =					mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8_UNORM")),
	B8_G8_R8_Snorm =					mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8_SNORM")),
	B8_G8_R8_Uscaled =					mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8_USCALED")),
	B8_G8_R8_Sscaled =					mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8_SSCALED")),
	B8_G8_R8_Uint =						mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8_UINT")),
	B8_G8_R8_Sint =						mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8_SINT")),
	B8_G8_R8_Srgb =						mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8_SRGB")),
	R8_G8_B8_A8_Unorm =					mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8A8_UNORM")),
	R8_G8_B8_A8_Snorm =					mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8A8_SNORM")),
	R8_G8_B8_A8_Uscaled =				mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8A8_USCALED")),
	R8_G8_B8_A8_Sscaled =				mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8A8_SSCALED")),
	R8_G8_B8_A8_Uint =					mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8A8_UINT")),
	R8_G8_B8_A8_Sint =					mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8A8_SINT")),
	R8_G8_B8_A8_Srgb =					mixin(DefineFormatEnum!("VK_FORMAT_R8G8B8A8_SRGB")),
	B8_G8_R8_A8_Unorm =					mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8A8_UNORM")),
	B8_G8_R8_A8_Snorm =					mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8A8_SNORM")),
	B8_G8_R8_A8_Uscaled =				mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8A8_USCALED")),
	B8_G8_R8_A8_Sscaled =				mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8A8_SSCALED")),
	B8_G8_R8_A8_Uint =					mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8A8_UINT")),
	B8_G8_R8_A8_Sint =					mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8A8_SINT")),
	B8_G8_R8_A8_Srgb =					mixin(DefineFormatEnum!("VK_FORMAT_B8G8R8A8_SRGB")),
	A8_B8_G8_R8_Unorm =					mixin(DefineFormatEnum!("VK_FORMAT_A8B8G8R8_UNORM_PACK32")),
	A8_B8_G8_R8_Snorm =					mixin(DefineFormatEnum!("VK_FORMAT_A8B8G8R8_SNORM_PACK32")),
	A8_B8_G8_R8_Uscaled =				mixin(DefineFormatEnum!("VK_FORMAT_A8B8G8R8_USCALED_PACK32")),
	A8_B8_G8_R8_Sscaled =				mixin(DefineFormatEnum!("VK_FORMAT_A8B8G8R8_SSCALED_PACK32")),
	A8_B8_G8_R8_Uint =					mixin(DefineFormatEnum!("VK_FORMAT_A8B8G8R8_UINT_PACK32")),
	A8_B8_G8_R8_Sint =					mixin(DefineFormatEnum!("VK_FORMAT_A8B8G8R8_SINT_PACK32")),
	A8_B8_G8_R8_Srgb =					mixin(DefineFormatEnum!("VK_FORMAT_A8B8G8R8_SRGB_PACK32")),
	A2_R10_G10_B10_Pack32_Unorm =		mixin(DefineFormatEnum!("VK_FORMAT_A2R10G10B10_UNORM_PACK32")),
	A2_R10_G10_B10_Pack32_Snorm =		mixin(DefineFormatEnum!("VK_FORMAT_A2R10G10B10_SNORM_PACK32")),
	A2_R10_G10_B10_Pack32_Uscaled =		mixin(DefineFormatEnum!("VK_FORMAT_A2R10G10B10_USCALED_PACK32")),
	A2_R10_G10_B10_Pack32_Sscaled =		mixin(DefineFormatEnum!("VK_FORMAT_A2R10G10B10_SSCALED_PACK32")),
	A2_R10_G10_B10_Pack32_Uint =		mixin(DefineFormatEnum!("VK_FORMAT_A2R10G10B10_UINT_PACK32")),
	A2_R10_G10_B10_Pack32_Sint =		mixin(DefineFormatEnum!("VK_FORMAT_A2R10G10B10_SINT_PACK32")),
	A2_B10_G10_R10_Pack32_Unorm =		mixin(DefineFormatEnum!("VK_FORMAT_A2B10G10R10_UNORM_PACK32")),
	A2_B10_G10_R10_Pack32_Snorm =		mixin(DefineFormatEnum!("VK_FORMAT_A2B10G10R10_SNORM_PACK32")),
	A2_B10_G10_R10_Pack32_Uscaled =		mixin(DefineFormatEnum!("VK_FORMAT_A2B10G10R10_USCALED_PACK32")),
	A2_B10_G10_R10_Pack32_Sscaled =		mixin(DefineFormatEnum!("VK_FORMAT_A2B10G10R10_SSCALED_PACK32")),
	A2_B10_G10_R10_Pack32_Uint =		mixin(DefineFormatEnum!("VK_FORMAT_A2B10G10R10_UINT_PACK32")),
	A2_B10_G10_R10_Pack32_Sint =		mixin(DefineFormatEnum!("VK_FORMAT_A2B10G10R10_SINT_PACK32")),
	R16_Unorm =							mixin(DefineFormatEnum!("VK_FORMAT_R16_UNORM")),
	R16_Snorm =							mixin(DefineFormatEnum!("VK_FORMAT_R16_SNORM")),
	R16_Uscaled =						mixin(DefineFormatEnum!("VK_FORMAT_R16_USCALED")),
	R16_Sscaled =						mixin(DefineFormatEnum!("VK_FORMAT_R16_SSCALED")),
	R16_Uint =							mixin(DefineFormatEnum!("VK_FORMAT_R16_UINT")),
	R16_Sint =							mixin(DefineFormatEnum!("VK_FORMAT_R16_SINT")),
	R16_Sfloat =						mixin(DefineFormatEnum!("VK_FORMAT_R16_SFLOAT")),
	R16_G16_Unorm =						mixin(DefineFormatEnum!("VK_FORMAT_R16G16_UNORM")),
	R16_G16_Snorm =						mixin(DefineFormatEnum!("VK_FORMAT_R16G16_SNORM")),
	R16_G16_Uscaled =					mixin(DefineFormatEnum!("VK_FORMAT_R16G16_USCALED")),
	R16_G16_Sscaled =					mixin(DefineFormatEnum!("VK_FORMAT_R16G16_SSCALED")),
	R16_G16_Uint =						mixin(DefineFormatEnum!("VK_FORMAT_R16G16_UINT")),
	R16_G16_Sint =						mixin(DefineFormatEnum!("VK_FORMAT_R16G16_SINT")),
	R16_G16_Sfloat =					mixin(DefineFormatEnum!("VK_FORMAT_R16G16_SFLOAT")),
	R16_G16_B16_Unorm =					mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16_UNORM")),
	R16_G16_B16_Snorm =					mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16_SNORM")),
	R16_G16_B16_Uscaled =				mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16_USCALED")),
	R16_G16_B16_Sscaled =				mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16_SSCALED")),
	R16_G16_B16_Uint =					mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16_UINT")),
	R16_G16_B16_Sint =					mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16_SINT")),
	R16_G16_B16_Sfloat =				mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16_SFLOAT")),
	R16_G16_B16_A16_Unorm =				mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16A16_UNORM")),
	R16_G16_B16_A16_Snorm =				mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16A16_SNORM")),
	R16_G16_B16_A16_Uscaled =			mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16A16_USCALED")),
	R16_G16_B16_A16_Sscaled =			mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16A16_SSCALED")),
	R16_G16_B16_A16_Uint =				mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16A16_UINT")),
	R16_G16_B16_A16_Sint =				mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16A16_SINT")),
	R16_G16_B16_A16_Sfloat =			mixin(DefineFormatEnum!("VK_FORMAT_R16G16B16A16_SFLOAT")),
	R32_Uint =							mixin(DefineFormatEnum!("VK_FORMAT_R32_UINT")),
	R32_Sint =							mixin(DefineFormatEnum!("VK_FORMAT_R32_SINT")),
	R32_Sfloat =						mixin(DefineFormatEnum!("VK_FORMAT_R32_SFLOAT")),
	R32_G32_Uint =						mixin(DefineFormatEnum!("VK_FORMAT_R32G32_UINT")),
	R32_G32_Sint =						mixin(DefineFormatEnum!("VK_FORMAT_R32G32_SINT")),
	R32_G32_Sfloat =					mixin(DefineFormatEnum!("VK_FORMAT_R32G32_SFLOAT")),
	R32_G32_B32_Uint =					mixin(DefineFormatEnum!("VK_FORMAT_R32G32B32_UINT")),
	R32_G32_B32_Sint =					mixin(DefineFormatEnum!("VK_FORMAT_R32G32B32_SINT")),
	R32_G32_B32_Sfloat =				mixin(DefineFormatEnum!("VK_FORMAT_R32G32B32_SFLOAT")),
	R32_G32_B32_A32_Uint =				mixin(DefineFormatEnum!("VK_FORMAT_R32G32B32A32_UINT")),
	R32_G32_B32_A32_Sint =				mixin(DefineFormatEnum!("VK_FORMAT_R32G32B32A32_SINT")),
	R32_G32_B32_A32_Sfloat =			mixin(DefineFormatEnum!("VK_FORMAT_R32G32B32A32_SFLOAT")),
	R64_Uint =							mixin(DefineFormatEnum!("VK_FORMAT_R64_UINT")),
	R64_Sint =							mixin(DefineFormatEnum!("VK_FORMAT_R64_SINT")),
	R64_Sfloat =						mixin(DefineFormatEnum!("VK_FORMAT_R64_SFLOAT")),
	R64_G64_Uint =						mixin(DefineFormatEnum!("VK_FORMAT_R64G64_UINT")),
	R64_G64_Sint =						mixin(DefineFormatEnum!("VK_FORMAT_R64G64_SINT")),
	R64_G64_Sfloat =					mixin(DefineFormatEnum!("VK_FORMAT_R64G64_SFLOAT")),
	R64_G64_B64_Uint =					mixin(DefineFormatEnum!("VK_FORMAT_R64G64B64_UINT")),
	R64_G64_B64_Sint =					mixin(DefineFormatEnum!("VK_FORMAT_R64G64B64_SINT")),
	R64_G64_B64_Sfloat =				mixin(DefineFormatEnum!("VK_FORMAT_R64G64B64_SFLOAT")),
	R64_G64_B64_A64_Uint =				mixin(DefineFormatEnum!("VK_FORMAT_R64G64B64A64_UINT")),
	R64_G64_B64_A64_Sint =				mixin(DefineFormatEnum!("VK_FORMAT_R64G64B64A64_SINT")),
	R64_G64_B64_A64_Sfloat =			mixin(DefineFormatEnum!("VK_FORMAT_R64G64B64A64_SFLOAT")),
	B10_G11_R11_Pack32_Ufloat =			mixin(DefineFormatEnum!("VK_FORMAT_B10G11R11_UFLOAT_PACK32")),
	E5_B9_G9_R9_Pack32_Ufloat =			mixin(DefineFormatEnum!("VK_FORMAT_E5B9G9R9_UFLOAT_PACK32")),

	// Depth & Stencil
	D16_Unorm =							mixin(DefineFormatEnum!("VK_FORMAT_D16_UNORM")),
	X8_D24_Unorm_Pack32 =				mixin(DefineFormatEnum!("VK_FORMAT_X8_D24_UNORM_PACK32")),
	D32_Sfloat =						mixin(DefineFormatEnum!("VK_FORMAT_D32_SFLOAT")),
	S8_Uint =							mixin(DefineFormatEnum!("VK_FORMAT_S8_UINT")),
	D16_Unorm_S8_Uint =					mixin(DefineFormatEnum!("VK_FORMAT_D16_UNORM_S8_UINT")),
	D24_Unorm_S8_Uint =					mixin(DefineFormatEnum!("VK_FORMAT_D24_UNORM_S8_UINT")),
	D32_Sfloat_S8_Uint =				mixin(DefineFormatEnum!("VK_FORMAT_D32_SFLOAT_S8_UINT")),
// ...
}

bool isDepthStencil(in ImgFmt img_fmt) pure nothrow @nogc
{
	return img_fmt.isDepth() || img_fmt.isStencil();
}

bool isDepth(in ImgFmt img_fmt) pure nothrow @nogc
{
	return img_fmt == ImgFmt.D16_Unorm
		|| img_fmt == ImgFmt.X8_D24_Unorm_Pack32
		|| img_fmt == ImgFmt.D32_Sfloat
		|| img_fmt == ImgFmt.D16_Unorm_S8_Uint
		|| img_fmt == ImgFmt.D24_Unorm_S8_Uint
		|| img_fmt == ImgFmt.D32_Sfloat_S8_Uint
		;
}

bool isStencil(in ImgFmt img_fmt) pure nothrow @nogc
{
	return img_fmt == ImgFmt.X8_D24_Unorm_Pack32
		|| img_fmt == ImgFmt.S8_Uint
		|| img_fmt == ImgFmt.D16_Unorm_S8_Uint
		|| img_fmt == ImgFmt.D24_Unorm_S8_Uint
		|| img_fmt == ImgFmt.D32_Sfloat_S8_Uint
		;
}
