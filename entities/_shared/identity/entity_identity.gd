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


static func from_entity(entity: PhysicsBody3D) -> EntityIdentity:
	if not entity:
		return null;

	if not EntityComponent.is_entity(entity):
		return null;

	var entity_entity_component: EntityComponent = EntityComponent.get_from(entity);

	if not entity_entity_component:
		return null;

	var entity_identity: EntityIdentity = entity_entity_component.identity;

	if not entity_identity:
		return null;

	return entity_identity;


static func from_entity_as_object(object: Object) -> EntityIdentity:
	if not object:
		return null;

	var entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(object);

	if not entity:
		return null;

	var entity_identity: EntityIdentity = from_entity(entity);

	if not entity_identity:
		return null;

	return entity_identity;


func is_name_default_name() -> bool:
	if name == DEFAULT_NAME:
		return true;
	else:
		return false;
