class_name EntityDamageBoostStatusReceiver
extends Node


signal added_damage_boost_request(request: DamageBoostRequest);
signal removed_damage_boost_request(request: DamageBoostRequest);

var _damage_boost_requests: Array[DamageBoostRequest] = [];

@onready var _status_receiver_hub_component: EntityStatusReceiverHubComponent = owner;


static func from_entity(entity: PhysicsBody3D) -> EntityDamageBoostStatusReceiver:
	if not entity:
		return null;

	if not EntityComponent.is_entity(entity):
		return null;

	var entity_entity_component: EntityComponent = EntityComponent.get_from(entity);

	if not entity_entity_component:
		return null;
	
	var entity_status_receiver_hub_component := EntityStatusReceiverHubComponent.from_entity(entity);

	if not entity_status_receiver_hub_component:
		return null;

	if not entity_status_receiver_hub_component.damage_boost_receiver:
		return null;

	return entity_status_receiver_hub_component.damage_boost_receiver;


static func from_entity_as_object(object: Object) -> EntityDamageBoostStatusReceiver:
	if not object:
		return null;

	var entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(object);

	if not entity:
		return null;

	var entity_damage_boost_status_receiver := EntityDamageBoostStatusReceiver.from_entity(entity);

	if not entity_damage_boost_status_receiver:
		return null;

	return entity_damage_boost_status_receiver;


func get_damage_boost_final_percentage() -> int:
	var final_percentage: int = 0;

	for request: DamageBoostRequest in _damage_boost_requests:
		final_percentage += request.how_much_in_percentage;

	final_percentage = clampi(final_percentage, 0, 100);

	return final_percentage;


func add_damage_boost_request(request: DamageBoostRequest) -> void:
	_damage_boost_requests.append(request);
	added_damage_boost_request.emit(request);


func remove_damage_boost_request(request: DamageBoostRequest) -> void:
	_damage_boost_requests.erase(request);
	removed_damage_boost_request.emit(request);


func _on_added_damage_boost_request(request: DamageBoostRequest) -> void:
	print("%s received a %s%% damage boost from %s !" % [
			_status_receiver_hub_component.entity_identity.name, 
			request.how_much_in_percentage, 
			request.requester_identity.name,
		]
	);


func _on_removed_damage_boost_request(request: DamageBoostRequest) -> void:
	print("%s revoked it's %s%% damage boost from %s..." % [
			request.requester_identity.name, 
			request.how_much_in_percentage, 
			_status_receiver_hub_component.entity_identity.name,
		]
	);


class DamageBoostRequest extends RefCounted:
	var how_much_in_percentage: int = 0:
		set(new_how_much_in_percentage):
			how_much_in_percentage = clampi(new_how_much_in_percentage, 0, 100);

	var requester_identity: EntityIdentity = EntityIdentity.new();

	@warning_ignore("shadowed_variable")
	func _init(how_much_in_percentage: int = 0, requester_identity := EntityIdentity.new()) -> void:
		self.how_much_in_percentage = how_much_in_percentage;
		self.requester_identity = requester_identity;
