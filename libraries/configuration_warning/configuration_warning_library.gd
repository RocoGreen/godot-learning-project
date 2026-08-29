class_name ConfigurationWarningLibrary
extends RefCounted


## Note: To call again when exported variable changes (by using a setter).
static func get_for_entity(entity: PhysicsBody3D) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not is_instance_valid(entity):
		warnings.append(
				"An exported variable expecting a `PhysicsBody3D` that could possibly be an " +
				"`Entity` is not set/valid."
		);

	else:
		if not entity.is_in_group(&"entities"):
			warnings.append(
					"An `Entity` assigned to an exported variable is invalid :\n" +
					"- Not in `entities` group."
			);

		if not entity.get_collision_mask_value(CollisionMaskLibrary.get_entities()):
			warnings.append(
					"An `Entity` assigned to an exported variable is invalid :\n" +
					"- Collision mask does not include `entities` layer."
			);

		if not entity.get_collision_mask_value(CollisionMaskLibrary.get_obstacles()):
			warnings.append(
					"An `Entity` assigned to an exported variable is invalid :\n" +
					"- Collision mask does not include `obstacles` layer."
			);

	return warnings;


## Note: To call again when exported variable changes (by using a setter).
static func get_for_playable(playable: CharacterBody3D) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not is_instance_valid(playable):
		warnings.append(
				"An exported variable expecting a `CharacterBody3D` that could possibly be a " +
				"`Playable` entity is not set/valid."
		);

	return warnings;


## Warning: An instance of the `EntityIdentity `resource can have it's properties 
## changed in runtime which also means it's configuration warnings. 
## Please subscribe to it's `changed` signal to be informed that a property changed 
## then call this function again.
static func get_for_entity_identity(identity: EntityIdentity) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not identity:
		warnings.append("An `EntityIdentity` exported variable is not set/valid.");

	elif identity.is_name_default_name():
		warnings.append(
				"An `EntityIdentity` assigned to an exported variable holds the default name. " +
				"You can ignore this warning if this is desired."
		);

	return warnings;


## Note: To call again when exported variable changes (by using a setter).
static func get_for_cb_3d_utils_component(
		cb_3d_utils_component: PlayableCharacterBody3DUtilsComponent,
) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not is_instance_valid(cb_3d_utils_component):
		warnings.append(
				"An exported variable expecting an `PlayableCharacterBody3DUtilsComponent` " + 
				"is not set/valid."
		);

	return warnings;


## Note: To call again when exported variable changes (by using a setter).
static func get_for_camera_component(
		camera_component: PlayableCameraComponent,
) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not is_instance_valid(camera_component):
		warnings.append(
				"An exported variable expecting an `PlayableCameraComponent` is not set/valid."
		);

	return warnings;
