class_name EntityDamageBoostStatusEffectReceiver
extends Node
# TODO: Error handling. Documentation. May have to do better naming.


signal granted(by_request: EntityDamageBoostStatusEffectGrantRequest);
signal ungranted(was_granted_by_request: EntityDamageBoostStatusEffectGrantRequest);

@export var _status_effect_receiver_hub_component: EntityStatusEffectReceiverHubComponent;

var _grant_requests: Array[EntityDamageBoostStatusEffectGrantRequest] = [];


static func from_entity(entity: PhysicsBody3D) -> EntityDamageBoostStatusEffectReceiver:
	if not entity:
		return null;

	if not EntityComponent.is_entity(entity):
		return null;

	var entity_entity_component: EntityComponent = EntityComponent.get_from(entity);

	if not entity_entity_component:
		return null;

	var entity_status_effect_receiver_hub_component: EntityStatusEffectReceiverHubComponent = \
			EntityStatusEffectReceiverHubComponent.from_entity(entity);

	if not entity_status_effect_receiver_hub_component:
		return null;

	if not entity_status_effect_receiver_hub_component.damage_boost_receiver:
		return null;

	return entity_status_effect_receiver_hub_component.damage_boost_receiver;


static func from_entity_as_object(object: Object) -> EntityDamageBoostStatusEffectReceiver:
	if not object:
		return null;

	var entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(object);

	if not entity:
		return null;

	var entity_damage_boost_status_effect_receiver := from_entity(entity);

	if not entity_damage_boost_status_effect_receiver:
		return null;

	return entity_damage_boost_status_effect_receiver;


func _init() -> void:
	granted.connect(_on_granted);
	ungranted.connect(_on_ungranted);


func grant(request: EntityDamageBoostStatusEffectGrantRequest) -> void:
	if not request.is_valid(): return;

	_grant_requests.append(request);
	granted.emit(request);


func ungrant(request: EntityDamageBoostStatusEffectGrantRequest) -> void:
	_grant_requests.erase(request);
	ungranted.emit(request);


func get_total_damage_boost_percentage() -> int:
	var final_percentage: int = 0;

	for grant_request: EntityDamageBoostStatusEffectGrantRequest in _grant_requests:
		final_percentage += grant_request.how_much_in_percentage;

	final_percentage = clampi(final_percentage, 0, 100);

	return final_percentage;


func _on_granted(by_request: EntityDamageBoostStatusEffectGrantRequest) -> void:
	var granter_entity_entity_component := EntityComponent.get_from(by_request.granter_entity);

	print("%s received a %s%% damage boost from %s !" % [
			_status_effect_receiver_hub_component.entity_component.entity_debug_name, 
			by_request.how_much_in_percentage, 
			granter_entity_entity_component.entity_debug_name,
		]
	);


func _on_ungranted(was_granted_by_request: EntityDamageBoostStatusEffectGrantRequest) -> void:
	var granter_entity: PhysicsBody3D = was_granted_by_request.granter_entity;
	var granter_entity_entity_component := EntityComponent.get_from(granter_entity);

	print("%s revoked it's %s%% damage boost from %s..." % [
			granter_entity_entity_component.entity_debug_name, 
			was_granted_by_request.how_much_in_percentage, 
			_status_effect_receiver_hub_component.entity_component.entity_debug_name,
		]
	);
