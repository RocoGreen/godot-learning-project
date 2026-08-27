@tool

class_name EntityIdentity
extends Resource


enum Team {
	TEAM_1,
	TEAM_2,
}

const DEFAULT_NAME: StringName = &"EMPTY";
const DEFAULT_TEAM: Team = Team.TEAM_1;

@export var name: StringName = DEFAULT_NAME:
	set(new_name):
		name = new_name;

		changed.emit();

@export var team: Team = DEFAULT_TEAM;


static func is_default(identity: EntityIdentity) -> bool:
	if identity.name == DEFAULT_NAME and identity.team == DEFAULT_TEAM:
		return true;
	else:
		return false;
