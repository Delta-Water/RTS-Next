class_name CollisionGroup
extends RefCounted

const UNIT: int = 1
const UNIT_TILE: int = 1 << 1
const TERRAIN_LAND: int = 1 << 8
const TERRAIN_WATER: int = 1 << 9
const TERRAIN_CLIFF: int = 1 << 10
const TERRAIN_LAVA: int = 1 << 11

const ALL: int = 0b1111_0000_0001
const ALL_TERRAIN: int = 0b1111_0000_0000
