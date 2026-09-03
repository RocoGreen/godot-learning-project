class_name EntityDamageBoostStatusReceiver
extends Node


signal added_damage_boost_request(request: EntityDamageBoostRequest);
signal removed_damage_boost_request(request: EntityDamageBoostRequest);

var _damage_boost_requests: Array[EntityDamageBoostRequest] = [];

@onready var _status_receiver_hub_component: EntityStatusReceiverHubComponent = owner;


func get_damage_boost_final_percentage() -> int:
	var final_percentage: int = 0;

	for request: EntityDamageBoostRequest in _damage_boost_requests:
		final_percentage += request.how_much_in_percentage;

	final_percentage = clampi(final_percentage, 0, 100);

	return final_percentage;


func add_damage_boost_request(request: EntityDamageBoostRequest) -> void:
	_damage_boost_requests.append(request);
	added_damage_boost_request.emit(request);


func remove_damage_boost_request(request: EntityDamageBoostRequest) -> void:
	_damage_boost_requests.erase(request);
	removed_damage_boost_request.emit(request);


func _on_added_damage_boost_request(request: EntityDamageBoostRequest) -> void:
	print("%s received a %s%% damage boost from %s !" % [
			_status_receiver_hub_component.entity_identity.name, 
			request.how_much_in_percentage, 
			request.requester_identity.name,
		]
	);


func _on_removed_damage_boost_request(request: EntityDamageBoostRequest) -> void:
	print("%s revoked it's %s%% damage boost from %s..." % [
			request.requester_identity.name, 
			request.how_much_in_percentage, 
			_status_receiver_hub_component.entity_identity.name,
		]
	);
