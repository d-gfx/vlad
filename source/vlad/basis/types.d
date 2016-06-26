/**
 *	types.d
 */
module vlad.basis.types;

import vlad.basis.vector;

alias ubyte		u8;		/// basic type
alias byte		s8;		/// ditto
alias ushort	u16;	/// ditto
alias short		s16;	/// ditto
alias uint		u32;	/// ditto
alias int		s32;	/// ditto
alias ulong		u64;	/// ditto
alias long		s64;	/// ditto
alias float		f32;	/// ditto
alias double	f64;	/// ditto

alias TVector!(f32, 2)	V2f;	/// 2d vector
alias TVector!(s32, 2)	V2s;	/// ditto
alias TVector!(u32, 2)	V2u;	/// ditto

alias TVector!(f32, 3)	V3f;	/// 3d vector
alias TVector!(s32, 3)	V3s;	/// ditto
alias TVector!(u32, 3)	V3u;	/// ditto

alias TVector!(f32, 4)	V4f;	/// 4d vector
alias TVector!(s32, 4)	V4s;	/// ditto
alias TVector!(u32, 4)	V4u;	/// ditto


alias TVector!(f32, 4)		C4f;	/// color
alias TVector!(s32, 4)		C4s;	/// ditto
alias TVector!(u32, 4)		C4u;	/// ditto
alias TVector!(ubyte, 4)	C4u8;	/// ditto
