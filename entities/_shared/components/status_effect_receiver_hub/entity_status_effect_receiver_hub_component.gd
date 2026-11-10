@tool

class_name EntityStatusEffectReceiverHubComponent
extends Node


@export_group("Dependencies")
@export var entity_component: EntityComponent;

@onready var damage_boost_receiver: EntityDamageBoostStatusEffectReceiver = %DamageBoost;
@onready var healing_received_reduction_receiver: EntityHealingReceivedReductionStatusEffectReceiver = \
		%HealingReceivedReduction;


static func from_entity(entity: PhysicsBody3D) -> EntityStatusEffectReceiverHubComponent:
	if not entity:
		return null;

	if not EntityComponent.is_entity(entity):
		return null;

	var entity_entity_component: EntityComponent = EntityComponent.get_from(entity);

	if not entity_entity_component:
		return null;

	var entity_status_effect_receiver_hub_component: EntityStatusEffectReceiverHubComponent = \
			entity_entity_component.status_effect_receiver_hub_component;

	if not entity_status_effect_receiver_hub_component:
		return null;

	return entity_status_effect_receiver_hub_component;


static func from_entity_as_object(object: Object) -> EntityStatusEffectReceiverHubComponent:
	if not object:
		return null;

	var entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(object);

	if not entity:
		return null;

	var entity_status_effect_receiver_hub_component := from_entity(entity);

	if not entity_status_effect_receiver_hub_component:
		return null;

	return entity_status_effect_receiver_hub_component;
