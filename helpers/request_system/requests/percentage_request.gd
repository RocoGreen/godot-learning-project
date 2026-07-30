class_name PercentageRequest
extends Request


var value: int = 0:
	set(new_value):
		value = clampi(new_value, 0, 100);


func _init(_value: int, _requester := EntityIdentity.new()) -> void:
	super(_requester);
	value = _value;
