class_name CollisionMaskLib
extends RefCounted


const _DATABASE: CollisionMaskLibDb = preload("uid://bhnmxd368ynsh");


static func get_entities_and_obstacles() -> int:
	return _DATABASE.entities_and_obstacles;
