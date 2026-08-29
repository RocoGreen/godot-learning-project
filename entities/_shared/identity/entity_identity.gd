@tool

class_name EntityIdentity
extends Resource


enum Team {
	TEAM_1,
	TEAM_2,
};

const DEFAULT_NAME: StringName = &"EMPTY";

@export var name: StringName = DEFAULT_NAME:
	set(new_name):
		name = new_name;

		changed.emit();

@export var team: Team = Team.TEAM_1:
	set(new_team):
		team = new_team;

		changed.emit();


func is_name_default_name() -> bool:
	if name == DEFAULT_NAME:
		return true;
	else:
		return false;
