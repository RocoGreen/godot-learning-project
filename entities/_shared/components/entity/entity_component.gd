@tool
class_name EntityComponent
extends Node


enum EntityTeam {
	INVALID_TEAM,
	TEAM_1,
	TEAM_2,
};

const DEFAULT_ENTITY_DEBUG_NAME: StringName = &"DEFAULT ENTITY DEBUG NAME";

@export_group("Dependencies")
@export var entity: PhysicsBody3D;

@export_group("Optional Dependencies")
## [b]Warning[/b]: Do NOT retrieve the component here.
## Use the method [method EntityHealthComponent.from_entity] instead.
@export var health_component: EntityHealthComponent;
## [b]Warning[/b]: Do NOT retrieve the component here.
## Use the method [method EntityStatusEffectReceiverHubComponent.from_entity] instead.
@export var status_effect_receiver_hub_component: EntityStatusEffectReceiverHubComponent;
## [b]Warning[/b]: Do NOT retrieve the component here.
## Use the method [method EntityPositionAnchorHubComponent.from_entity] instead.
@export var position_anchor_hub_component: EntityPositionAnchorHubComponent;

@export_group("Entity Settings")
@export var entity_debug_name: StringName = DEFAULT_ENTITY_DEBUG_NAME;
@export var entity_team: EntityTeam = EntityTeam.INVALID_TEAM;


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


static func in_same_team(entity_a: PhysicsBody3D, entity_b: PhysicsBody3D) -> bool:
	if not is_entity(entity_a) or not is_entity(entity_b): 
		return false;

	var entity_a_entity_component: EntityComponent = get_from(entity_a);
	var entity_b_entity_component: EntityComponent = get_from(entity_b);

	if not entity_a_entity_component or not entity_b_entity_component:
		return false;

	var entity_a_team: EntityTeam = entity_a_entity_component.entity_team;
	var entity_b_team: EntityTeam = entity_b_entity_component.entity_team;

	if entity_a_team == EntityTeam.INVALID_TEAM:
		return false;

	if entity_b_team == EntityTeam.INVALID_TEAM:
		return false;

	if entity_a_team == entity_b_team:
		return true;
	else:
		return false;


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint(): return;

	update_configuration_warnings();


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLibrary.get_for_entity(entity));

	return warnings;
