@tool

class_name EntityIdentity
extends Resource


const DEFAULT_NAME: StringName = &"EMPTY";

@export var name: StringName = DEFAULT_NAME:
	set(new_name):
		name = new_name;
		
		changed.emit();


static func is_default(identity: EntityIdentity) -> bool:
	if identity.name == DEFAULT_NAME:
		return true;
	else:
		return false;
