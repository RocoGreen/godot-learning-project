class_name IntValueRequest
extends Request


func _init(_value: int, _requester: EntityIdentity = EntityIdentity.new()) -> void:
	super(_requester);
	value = _value;


@export var value: int = 0;
