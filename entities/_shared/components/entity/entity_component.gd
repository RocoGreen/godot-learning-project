@tool

class_name EntityComponent
extends Node


@export_group("Dependencies")
@export var entity: PhysicsBody3D;
## [b]Warning[/b]: Do NOT retrieve the identity here.
## Use the method [method EntityIdentity.from_entity] instead.
@export var identity: EntityIdentity = EntityIdentity.new();

@export_group("Optional Dependencies")
## [b]Warning[/b]: Do NOT retrieve the component here.
## Use the method [method EntityHealthComponent.from_entity] instead.
@export var health_component: EntityHealthComponent;
## [b]Warning[/b]: Do NOT retrieve the component here.
## Use the method [method EntityStatusReceiverHubComponent.from_entity] instead.
@export var status_receiver_hub_component: EntityStatusReceiverHubComponent;
## [b]Warning[/b]: Do NOT retrieve the component here.
## Use the method [method EntityPositionAnchorHubComponent.from_entity] instead.
@export var position_anchor_hub_component: EntityPositionAnchorHubComponent;


static func is_entity(node: Node) -> bool:
	if not node:
		return false;

	if node is not PhysicsBody3D:
		return false;

	var entity_component: EntityComponent = EntityComponent.get_from(node);

	if not entity_component:
		return false;

	return true;


static func is_object_an_entity(object: Object) -> bool:
	if not object:
		return false;

	if object is not PhysicsBody3D:
		return false;

	var object_is_an_entity: bool = is_entity(object);

	if not object_is_an_entity:
		return false;

	return true;


static func cast_object_to_entity(object: Object) -> PhysicsBody3D:
	if not object:
		return null;

	if object is not PhysicsBody3D:
		return null;

	if not is_entity(object):
		return null;

	return object;


static func get_from(node: Node) -> EntityComponent:
	if not node:
		return;

	if node.get_child_count() <= 0:
		return null;

	var entity_component: EntityComponent = node.get_child(0) as EntityComponent;

	if not entity_component:
		return null;

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
