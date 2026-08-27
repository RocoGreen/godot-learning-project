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
@export var health_component: EntityHealthComponent;
@export var status_receiver_hub_component: EntityStatusReceiverHubComponent;
@export var position_anchor_hub_component: EntityPositionAnchorHubComponent;


@warning_ignore("shadowed_variable")
static func from_entity(entity: PhysicsBody3D) -> EntityComponent:
	var entity_component: EntityComponent = entity.get_child(0) as EntityComponent;

	return entity_component;


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint(): return;

	update_configuration_warnings();


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLibrary.get_for_entity(entity));

	warnings.append_array(ConfigurationWarningLibrary.get_for_entity_identity(identity));

	return warnings;


func _on_identity_changed() -> void:
	update_configuration_warnings();
