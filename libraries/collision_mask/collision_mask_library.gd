class_name CollisionMaskLibrary
extends RefCounted


# The database is a resource loaded inside the "database" folder located 
# at this script's file path.
const _DATABASE: CollisionMaskLibraryDatabase = preload("uid://bhnmxd368ynsh");


static func get_entities_and_obstacles() -> int:
	return _DATABASE.entities_and_obstacles;


static func get_entities() -> int:
	return _DATABASE.entities;


static func get_obstacles() -> int:
	return _DATABASE.obstacles;
