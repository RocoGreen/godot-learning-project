class_name EntityDamageBoostRequest 
extends RefCounted


var how_much_in_percentage: int = 0:
	set(new_how_much_in_percentage):
		how_much_in_percentage = clampi(new_how_much_in_percentage, 0, 100);

var requester_identity: EntityIdentity = EntityIdentity.new();


@warning_ignore("shadowed_variable")
func _init(how_much_in_percentage: int = 0, requester_identity := EntityIdentity.new()) -> void:
	self.how_much_in_percentage = how_much_in_percentage;
	self.requester_identity = requester_identity;
