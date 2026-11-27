class_name SeedMixer
extends RefCounted

const MASK := 0xFFFFFFFF
const STREAM_STEP := 0x9E3779B1
const MIX_A := 0x85EBCA6B
const MIX_B := 0xC2B2AE35


static func derive(base_seed: int, stream: int) -> int:
	var offset := (stream + 1) * STREAM_STEP
	return _scramble((base_seed + offset) & MASK)


static func _scramble(value: int) -> int:
	value = value ^ (value >> 16)
	value = (value * MIX_A) & MASK
	value = value ^ (value >> 13)
	value = (value * MIX_B) & MASK
	return value ^ (value >> 16)
