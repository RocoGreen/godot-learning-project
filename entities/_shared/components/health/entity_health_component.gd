@tool
class_name EntityHealthComponent
extends Node


signal health_changed(old_health: float, new_health: float);
signal healed(amount: float, old_health: float, new_health: float, by_request: EntityHealthHealingRequest);
signal damaged(amount: float, old_health: float, new_health: float, by_request: EntityHealthDamageRequest);

@export_group("Dependencies")
@export var _entity: PhysicsBody3D;
@export var _entity_component: EntityComponent;

@export_group("Settings")
@export var _current_health: float = 100.0: get = get_current_health;
@export var _maximum_health: float = 100.0: get = get_maximum_health;


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
	healed.connect(_on_healed);
	damaged.connect(_on_damaged);


func heal(by_healing_request: EntityHealthHealingRequest) -> void:
	if not by_healing_request: return;
	if not by_healing_request.is_valid(): return;
	if not is_request_allowed_to_heal(by_healing_request): return;

	var old_health: float = _current_health;
	var new_health: float = clampf(old_health + by_healing_request.amount, 0.0, _maximum_health);

	if old_health == new_health: return;

	_current_health = new_health;

	health_changed.emit(old_health, new_health);
	healed.emit(
			by_healing_request.amount, 
			old_health, 
			_current_health, 
			by_healing_request,
	);


func damage(by_damage_request: EntityHealthDamageRequest) -> void:
	if not by_damage_request: return;
	if not by_damage_request.is_valid(): return;
	if not is_request_allowed_to_damage(by_damage_request): return;

	var old_health: float = _current_health;
	var new_health: float = clampf(old_health - by_damage_request.amount, 0.0, _maximum_health);

	if old_health == new_health: return;

	_current_health = new_health;

	health_changed.emit(old_health, new_health);
	damaged.emit(
			by_damage_request.amount, 
			old_health, 
			_current_health, 
			by_damage_request,
	);


func is_request_allowed_to_heal(request: EntityHealthHealingRequest) -> bool:
	if not request:
		return false;

	if not request.heal_any_entity and not EntityComponent.in_same_team(request.healer_entity, _entity):
		return false;

	if is_full_health():
		return false;

	return true;


func is_request_allowed_to_damage(request: EntityHealthDamageRequest) -> bool:
	if not request.is_valid(): 
		return false;

	if not request.damage_any_entity and EntityComponent.in_same_team(request.attacker_entity, _entity):
		return false;

	if _current_health <= 0.0:
		return false;

	return true;


func is_full_health() -> bool:
	if _current_health >= _maximum_health:
		return true;
	else:
		return false;


func get_current_health() -> float:
	return _current_health;


func get_maximum_health() -> float:
	return _maximum_health;


## Called when the entity got healed and processed here to print debug information about what happened.
func _on_healed(
		amount: float, 
		_old_health: float, 
		_new_health: float, 
		by_request: EntityHealthHealingRequest,
) -> void:
	var healer_entity_entity_component := EntityComponent.get_from(by_request.healer_entity);

	print(
			"=== ENTITY HEALED DEBUG ===\n" +
			"- Healer: %s\n" % healer_entity_entity_component.entity_debug_name +
			"- Receiver: %s\n" % _entity_component.entity_debug_name +
			"- Healing received: %s\n" % amount +
			"- Current health: %s / %s\n\n" % [_current_health, _maximum_health]
	);


## Called when the entity took damage and processed here to print debug information about what happened.
func _on_damaged(
		amount: float, 
		_old_health: float, 
		_new_health: float, 
		by_request: EntityHealthDamageRequest,
) -> void:
	var attacker_entity_entity_component := EntityComponent.get_from(by_request.attacker_entity);

	print(
			"=== ENTITY DAMAGED DEBUG ===\n" +
			"- Attacker: %s\n" % attacker_entity_entity_component.entity_debug_name +
			"- Attacked: %s\n" % _entity_component.entity_debug_name +
			"- Damage taken: %s\n" % amount +
			"- Current health: %s / %s\n\n" % [_current_health, _maximum_health]
	);
