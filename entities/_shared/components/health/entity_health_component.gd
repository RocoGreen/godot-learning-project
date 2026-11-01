@tool

class_name EntityHealthComponent
extends Node


signal health_changed(old_health: float, new_health: float);
signal healed(amount: float, old_health: float, new_health: float, by_request: EntityHealthHealingRequest);
signal damaged(amount: float, old_health: float, new_health: float, by_request: EntityHealthDamageRequest);


@export_group("Dependencies")
@export var entity_identity: EntityIdentity = EntityIdentity.new():
	set(new_entity_identity):
		if entity_identity and Engine.is_editor_hint():
			entity_identity.changed.disconnect(_on_entity_identity_changed);

		entity_identity = new_entity_identity;

		if Engine.is_editor_hint():
			update_configuration_warnings();

			if entity_identity:
				entity_identity.changed.connect(_on_entity_identity_changed);

@export_group("Settings")
@export var current_health: float = 100.0;
@export var maximum_health: float = 100.0;


static func from_entity(entity: PhysicsBody3D) -> EntityHealthComponent:
	if not entity:
		return null;

	if not EntityComponent.is_entity(entity):
		return null;

	var entity_entity_component: EntityComponent = EntityComponent.get_from(entity);

	if not entity_entity_component:
		return null;

	var entity_health_component: EntityHealthComponent = entity_entity_component.health_component;

	if not entity_health_component:
		return null;

	return entity_health_component;


func from_entity_as_object(object: Object) -> EntityHealthComponent:
	if not object:
		return null;

	var entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(object);

	if not entity:
		return null;

	var entity_health_component: EntityHealthComponent = from_entity(entity);

	if not entity_health_component:
		return null;

	return entity_health_component;


func _init() -> void:
	if Engine.is_editor_hint() and entity_identity:
		entity_identity.changed.connect(_on_entity_identity_changed);


func _get_configuration_warnings() -> PackedStringArray:
	return ConfigurationWarningLibrary.get_for_entity_identity(entity_identity);


func heal(by_healing_request: EntityHealthHealingRequest) -> void:
	if not by_healing_request: return;
	if not by_healing_request.is_valid(): return;
	if not is_request_allowed_to_heal(by_healing_request): return;

	var old_health: float = current_health;
	var new_health: float = clampf(old_health + by_healing_request.amount, 0.0, maximum_health);

	if old_health == new_health: return;

	current_health = new_health;

	health_changed.emit(old_health, new_health);
	healed.emit(
			by_healing_request.amount, 
			old_health, 
			current_health, 
			by_healing_request,
	);


func damage(by_damage_request: EntityHealthDamageRequest) -> void:
	if not by_damage_request: return;
	if not by_damage_request.is_valid(): return;
	if not is_request_allowed_to_damage(by_damage_request): return;

	var old_health: float = current_health;
	var new_health: float = clampf(old_health - by_damage_request.amount, 0.0, maximum_health);

	if old_health == new_health: return;

	current_health = new_health;

	health_changed.emit(old_health, new_health);
	damaged.emit(
			by_damage_request.amount, 
			old_health, 
			current_health, 
			by_damage_request,
	);


func is_request_allowed_to_heal(request: EntityHealthHealingRequest) -> bool:
	if not request:
		return false;

	if not request.heal_any_entity:
		var healer_entity_team: EntityIdentity.Team = request.healer_entity_identity.team;

		if healer_entity_team == null:
			return false;
		
		if healer_entity_team != entity_identity.team:
			return false;

	if is_full_health():
		return false;

	return true;


func is_request_allowed_to_damage(request: EntityHealthDamageRequest) -> bool:
	if not request.damage_any_entity:
		var healer_entity_team: EntityIdentity.Team = request.attacker_entity_identity.team;

		if healer_entity_team == null:
			return false;
		
		if healer_entity_team == entity_identity.team:
			return false;

	if current_health <= 0.0:
		return false;

	return true;


func is_full_health() -> bool:
	if current_health >= maximum_health:
		return true;
	else:
		return false;


func _on_entity_identity_changed() -> void:
	update_configuration_warnings();


## Called when the entity got healed and processed here to print debug information about what happened.
func _on_healed(
		amount: float, 
		_old_health: float, 
		_new_health: float, 
		by_request: EntityHealthHealingRequest,
) -> void:
	print(
			"=== HEALING DEBUG ===\n" +
			"- Healer: %s\n" % by_request.healer_entity_identity.name +
			"- Receiver: %s\n" % entity_identity.name +
			"- Healing received: %s\n" % amount +
			"- Current health: %s / %s\n\n" % [current_health, maximum_health]
	);


## Called when the entity took damage and processed here to print debug information about what happened.
func _on_damaged(
		amount: float, 
		_old_health: float, 
		_new_health: float, 
		by_request: EntityHealthDamageRequest,
) -> void:
	print(
			"=== DAMAGE DEBUG ===\n" +
			"- Attacker: %s\n" % by_request.attacker_entity_identity.name +
			"- Attacked: %s\n" % entity_identity.name +
			"- Damage taken: %s\n" % amount +
			"- Current health: %s / %s\n\n" % [current_health, maximum_health]
	);
