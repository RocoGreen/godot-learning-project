@tool

class_name EntityComponent
extends Node


@export_group("Dependencies")
# Holding the Entity (that is supposed to be a `PhysicsBody3D`) so it can be accessed outside 
# of it's scene.
@export var entity: PhysicsBody3D;

# Warning: Not checked if it's at default values when component is _ready();
@export var identity: EntityIdentity = EntityIdentity.new();

@export_group("Optional Dependencies")
# exp is exported abbreviated. So, exported components to be accessed outside of Entity's scene.
# Note : Mind that these exported components aren't mandatory to exist in the Entity's scene.
@export var exp_health_component: EntityHealthComponent;
@export var exp_status_receiver_component: EntityStatusReceiverComponent;


## Note: Will return null if resumed after the assert(). So please stop the game if no safe check is 
## in place.
@warning_ignore("shadowed_variable")
static func from_entity_or_assert(entity: PhysicsBody3D) -> EntityComponent:
	var entity_component: EntityComponent;

	# Entities are supposed to have the component as first child. So if it isn't there, then the 
	# Entity is invalid due to misconfiguration. Node groups are used to know if an Entity 
	# is indeed one. Not by trying to get the `EntityComponent`.
	if entity.get_child_count() > 0: 
		entity_component = entity.get_child(0) as EntityComponent;

	assert(
			is_instance_valid(entity_component), 

			'"EntityComponent" has not been found in the entity. ' + \
			"Please put one as first child of the entity's scene."
	);

	return entity_component;


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	AssertLib.assert_if_entity_not_found(entity);

	AssertLib.assert_if_entity_identity_not_found(identity);


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint(): return;

	update_configuration_warnings();


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLib.get_for_entity(entity));

	if is_instance_valid(entity):
		if not entity.is_in_group(&"entities"):
			warnings.append(
					"An Entity assigned to an exported variable is invalid : " +
					"Not in `entities` group."
			);

		elif entity.is_in_group(&"allies") and entity.is_in_group(&"enemies"):
			warnings.append(
					"An Entity assigned to an exported variable is invalid : " + 
					"Is in `allies` and `enemies` group " +
					"at the same time. Entity should not be in both."
			);

		elif not entity.is_in_group(&"allies") and not entity.is_in_group(&"enemies"):
			warnings.append("An Entity assigned to an exported variable is invalid : " + 
					"Is in `entities` group " +
					"but not in `allies` or `enemies` group too."
			);

	warnings.append_array(ConfigurationWarningLib.get_for_entity_identity(identity));

	return warnings;


func _on_identity_changed() -> void:
	update_configuration_warnings();
