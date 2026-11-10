class_name EntityHealingReceivedReductionStatusEffectReceiver
extends Node


signal inflicted(by_request: EntityHealingReceivedReductionStatusEffectInflictRequest);
signal uninflicted(was_inflicted_by_request: EntityHealingReceivedReductionStatusEffectInflictRequest);

@export var _status_effect_receiver_hub_component: EntityStatusEffectReceiverHubComponent;

var _inflict_requests: Array[EntityHealingReceivedReductionStatusEffectInflictRequest] = [];


static func from_entity(entity: PhysicsBody3D) -> EntityHealingReceivedReductionStatusEffectReceiver:
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

	if not entity_status_effect_receiver_hub_component.healing_received_reduction_receiver:
		return null;

	return entity_status_effect_receiver_hub_component.healing_received_reduction_receiver;


static func from_entity_as_object(object: Object) -> EntityHealingReceivedReductionStatusEffectReceiver:
	if not object:
		return null;

	var entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(object);

	if not entity:
		return null;

	var entity_healing_received_reduction_status_effect_receiver := from_entity(entity);

	if not entity_healing_received_reduction_status_effect_receiver:
		return null;

	return entity_healing_received_reduction_status_effect_receiver;


func _init() -> void:
	inflicted.connect(_on_inflicted);
	uninflicted.connect(_on_uninflicted);


func inflict(by_request: EntityHealingReceivedReductionStatusEffectInflictRequest) -> void:
	if by_request is not EntityHealingReceivedReductionStatusEffectInflictRequest: return;
	if not by_request.is_valid(): return;
	if _inflict_requests.has(by_request): return;

	_inflict_requests.append(by_request);
	inflicted.emit(by_request);

	if by_request.duration_seconds <= 0.0: return;

	await get_tree().create_timer(by_request.duration_seconds).timeout;

	uninflict(by_request);


func uninflict(
		was_inflicted_by_request: EntityHealingReceivedReductionStatusEffectInflictRequest
) -> void:
	if was_inflicted_by_request is not EntityHealingReceivedReductionStatusEffectInflictRequest: return;
	if not _inflict_requests.has(was_inflicted_by_request): return;

	_inflict_requests.erase(was_inflicted_by_request);
	uninflicted.emit(was_inflicted_by_request);


func get_total_healing_reduction_percentage() -> int:
	if _inflict_requests.is_empty(): 
		return 0;

	var total_percentage: int = 0;

	for inflict_request: EntityHealingReceivedReductionStatusEffectInflictRequest in _inflict_requests:
		total_percentage += inflict_request.how_much_in_percentage;

	total_percentage = clampi(total_percentage, 0, 100);

	return total_percentage;


func is_active() -> bool:
	if not _inflict_requests.is_empty():
		return true;
	else:
		return false;


func can_inflict_request_inflict(
		request: EntityHealingReceivedReductionStatusEffectInflictRequest
) -> bool:
	if request is not EntityHealingReceivedReductionStatusEffectInflictRequest: 
		return false;

	if not request.is_valid():
		return false;

	if _inflict_requests.has(request):
		return false;

	return true;


func _on_inflicted(by_request: EntityHealingReceivedReductionStatusEffectInflictRequest) -> void:
	var inflicter_entity_entity_component := EntityComponent.get_from(by_request.inflicter_entity);

	if not inflicter_entity_entity_component: return;

	print('"%s" got an inflicted %s%% healing received reduction from "%s".' % [
		_status_effect_receiver_hub_component.entity_component.entity_debug_name,
		by_request.how_much_in_percentage,
		inflicter_entity_entity_component.entity_debug_name,
	]);


func _on_uninflicted(
		was_inflicted_by_request: EntityHealingReceivedReductionStatusEffectInflictRequest,
) -> void:
	var inflicter_entity_entity_component: EntityComponent = EntityComponent.get_from(
			was_inflicted_by_request.inflicter_entity,
	);

	if not inflicter_entity_entity_component: return;

	print('"%s" got it\'s inflicted %s%% healing received reduction from "%s" removed.' % [
		_status_effect_receiver_hub_component.entity_component.entity_debug_name,
		was_inflicted_by_request.how_much_in_percentage,
		inflicter_entity_entity_component.entity_debug_name,
	]);
