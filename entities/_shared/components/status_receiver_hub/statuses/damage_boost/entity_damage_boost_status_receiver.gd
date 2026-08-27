class_name EntityDamageBoostStatusReceiver
extends Node


signal added_damage_boost_request(request: DamageBoostRequest);
signal removed_damage_boost_request(request: DamageBoostRequest);

var _damage_boost_requests: Array[DamageBoostRequest] = [];

@onready var _status_receiver_hub_component: EntityStatusReceiverHubComponent = owner;


func add_damage_boost_request(request: DamageBoostRequest) -> void:
	_damage_boost_requests.append(request);
	added_damage_boost_request.emit(request);


func remove_damage_boost_request(request: DamageBoostRequest) -> void:
	_damage_boost_requests.erase(request);
	removed_damage_boost_request.emit(request);


func get_damage_boost_final_percentage() -> int:
	var final_percentage: int = 0;

	for request: DamageBoostRequest in _damage_boost_requests:
		final_percentage += request.how_much_in_percentage;

	final_percentage = clampi(final_percentage, 0, 100);

	return final_percentage;


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
