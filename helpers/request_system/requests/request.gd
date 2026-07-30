class_name Request
extends RefCounted


func _init(_requester: EntityIdentity = EntityIdentity.new()) -> void:
	requester = _requester;


@export var id: int = -1;
@export var requester: EntityIdentity = EntityIdentity.new();
