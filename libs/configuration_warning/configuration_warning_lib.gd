class_name ConfigurationWarningLib
extends RefCounted


## Note: To call again when exported variable changes (by using a setter).
static func get_for_entity(entity: PhysicsBody3D) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not is_instance_valid(entity):
		warnings.append("An exported variable expecting an Entity is not set/valid.");

	return warnings;


## Warning: An instance of the `EntityIdentity `resource can have it's properties 
## changed in runtime which also means it's configuration warnings. 
## Please subscribe to it's `changed` signal to be informed that a property changed 
## then call this function again.
static func get_for_entity_identity(identity: EntityIdentity) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not identity:
		warnings.append("An `EntityIdentity` exported variable is not set/valid.");

	elif EntityIdentity.is_default(identity):
		warnings.append(
				"An `EntityIdentity` exported variable holds a default identity. " +
				"You can ignore this warning if this is desired."
		);

	return warnings;


## Note: To call again when exported variable changes (by using a setter).
static func get_for_cb_3d_utils_component(
		cb_3d_utils_component: EntityCharacterBody3DUtilsComponent
) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not is_instance_valid(cb_3d_utils_component):
		warnings.append(
				"An exported variable expecting an `EntityCharacterBody3DUtilsComponent` " + 
				"is not set/valid."
		);

	return warnings;


## Note: To call again when exported variable changes (by using a setter).
static func get_for_camera_component(
		camera_component: EntityCameraComponent
) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not is_instance_valid(camera_component):
		warnings.append(
				"An exported variable expecting an `EntityCameraComponent` is not set/valid."
		);

	return warnings;
