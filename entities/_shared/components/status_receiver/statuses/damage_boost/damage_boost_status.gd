class_name EntityDamageBoostStatus
extends Node


@onready var status_receiver: EntityStatusReceiverComponent = get_parent();


func _ready() -> void:
	status_receiver.damage_boost_requests.new_request.connect(_on_damage_boost_new_request);
	status_receiver.damage_boost_requests.removed_request.connect(_on_damage_boost_removed_request);


func get_damage_boost_final_percentage() -> int:
	var final_percentage: int = 0;
	
	for request: IntValueRequest in status_receiver.damage_boost_requests.get_requests():
		final_percentage += request.value;
	
	return clampi(final_percentage, 0, 100);


func _on_damage_boost_new_request(request: Request) -> void:
	request = request as IntValueRequest;
	
	print("%s received a %s%% damage boost from %s !" \
			% [status_receiver.entity_identity.name, request.value, request.requester.name]);


func _on_damage_boost_removed_request(request: Request) -> void:
	request = request as IntValueRequest;
	
	print("%s revoked it's %s%% damage boost from %s..." \
			% [request.requester.name, request.value, status_receiver.entity_identity.name]);
