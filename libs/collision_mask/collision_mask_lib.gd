class_name CollisionMaskLib
extends RefCounted


# The database is a resource loaded inside the "db" folder located at this script's file path.
const _DATABASE: CollisionMaskLibDb = preload("uid://bhnmxd368ynsh");


static func get_entities_and_obstacles() -> int:
	return _DATABASE.entities_and_obstacles;
