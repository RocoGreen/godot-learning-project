class_name AssertLib
extends RefCounted


static func assert_if_entity_not_found(entity: PhysicsBody3D) -> void:
	assert(
			is_instance_of(entity, PhysicsBody3D),
			
			"Expected `entity` variable to hold a `PhysicsBody3D` Entity " +
			"but is `%s`. " % str(entity) +
			"Please check the debugger for more information."
	);


static func assert_if_cb_3d_entity_not_found(entity: CharacterBody3D) -> void:
	assert(
			is_instance_of(entity, CharacterBody3D),

			"Expected `entity` variable to hold a `CharacterBody3D` Entity " +
			"but is `%s`. " % str(entity) +
			"Please check the debugger for more information."
	);


static func assert_if_entity_identity_not_found(entity_identity: EntityIdentity) -> void:
	assert(
			is_instance_of(entity_identity, EntityIdentity),

			"Expected `entity_identity` variable to hold a `EntityIdentity` " +
			"but is `%s`. " % str(entity_identity) +
			"Please check the debugger for more information."
	);


static func assert_if_camera_component_not_found(camera_component: PlayableCameraComponent) -> void:
	assert(
			is_instance_of(camera_component, PlayableCameraComponent),

			"Expected `camera_component` variable to hold a `PlayableCameraComponent` " +
			"but is `%s`. " % str(camera_component) +
			"Please check the debugger for more information."
	);


static func assert_if_cb_3d_utils_component_not_found(
		cb_3d_utils_component: PlayableCharacterBody3DUtilsComponent
) -> void:
	assert(
			is_instance_of(cb_3d_utils_component, PlayableCharacterBody3DUtilsComponent),

			"Expected `cb_3d_utils_component` variable to hold a " +
			"`PlayableCharacterBody3DUtilsComponent` but is `%s`. " % str(cb_3d_utils_component) +
			"Please check the debugger for more information."
	);
