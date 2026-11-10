class_name EntityDamageReceivedReductionStatusEffectReceiver
extends Node


signal granted(by_request: EntityDamageReceivedReductionStatusEffectGrantRequest);
signal ungranted(was_granted_by_request: EntityDamageReceivedReductionStatusEffectGrantRequest);

@export var _status_effect_receiver_hub_component: EntityStatusEffectReceiverHubComponent;

var _grant_requests: Array[EntityDamageReceivedReductionStatusEffectGrantRequest] = [];


static func from_entity(entity: PhysicsBody3D) -> EntityDamageReceivedReductionStatusEffectReceiver:
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

	if not entity_status_effect_receiver_hub_component.damage_received_reduction_receiver:
		return null;

	return entity_status_effect_receiver_hub_component.damage_received_reduction_receiver;


static func from_entity_as_object(object: Object) -> EntityDamageReceivedReductionStatusEffectReceiver:
	if not object:
		return null;

	var entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(object);

	if not entity:
		return null;

	var entity_damage_received_reduction_status_effect_receiver := from_entity(entity);

	if not entity_damage_received_reduction_status_effect_receiver:
		return null;

	return entity_damage_received_reduction_status_effect_receiver;


func _init() -> void:
	granted.connect(_on_granted);
	ungranted.connect(_on_ungranted);


func grant(by_request: EntityDamageReceivedReductionStatusEffectGrantRequest) -> void:
	if by_request is not EntityDamageReceivedReductionStatusEffectGrantRequest: return;
	if not by_request.is_valid(): return;
	if _grant_requests.has(by_request): return;

	_grant_requests.append(by_request);
	granted.emit(by_request);

	if not by_request.duration_seconds <= 0.0: return;

	await get_tree().create_timer(by_request.duration_seconds).timeout;

	ungrant(by_request);


func ungrant(request_that_granted: EntityDamageReceivedReductionStatusEffectGrantRequest) -> void:
	if request_that_granted is not EntityDamageReceivedReductionStatusEffectGrantRequest: return;
	if not _grant_requests.has(request_that_granted): return;

	_grant_requests.erase(request_that_granted);
	ungranted.emit(request_that_granted);


func get_total_damage_reduction_percentage() -> int:
	if not is_active(): 
		return 0;

	var total_percentage: int = 0;

	for grant_request: EntityDamageReceivedReductionStatusEffectGrantRequest in _grant_requests:
		total_percentage += grant_request.how_much_in_percentage;

	total_percentage = clampi(total_percentage, 0, 100);

	return total_percentage;


func is_active() -> bool:
	if not _grant_requests.is_empty():
		return true;
	else:
		return false;


func can_grant_request_grant(request: EntityDamageReceivedReductionStatusEffectGrantRequest) -> bool:
	if request is not EntityDamageReceivedReductionStatusEffectGrantRequest:
		return false;

	if not request.is_valid(): 
		return false;

	if _grant_requests.has(request):
		return false;

	return true;


func _on_granted(by_request: EntityDamageReceivedReductionStatusEffectGrantRequest) -> void:
	var granter_entity_entity_component := EntityComponent.get_from(by_request.granter_entity);

	if not granter_entity_entity_component: return;

	print('"%s" just got granted a %s%% damage received reduction by "%s".' % [
		_status_effect_receiver_hub_component.entity_component.entity_debug_name,
		by_request.how_much_in_percentage,
		granter_entity_entity_component.entity_debug_name,
	]);


func _on_ungranted(was_granted_by_request: EntityDamageReceivedReductionStatusEffectGrantRequest) -> void:
	var granter_entity_entity_component: EntityComponent = EntityComponent.get_from(
			was_granted_by_request.granter_entity,
	);

	if not granter_entity_entity_component: return;

	print('"%s" just got it\'s %s%% damage received reduction granted by "%s" removed.' % [
		_status_effect_receiver_hub_component.entity_component.entity_debug_name,
		was_granted_by_request.how_much_in_percentage,
		granter_entity_entity_component.entity_debug_name,
	]);
