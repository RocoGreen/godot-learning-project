@tool

class_name EntityHealthComponent
extends Node


signal health_changed(old_health: float, new_health: float, source: EntityIdentity);
signal healed(amount: float, old_health: float, new_health: float, healer: EntityIdentity);
signal damaged(amount: float, old_health: float, new_health: float, attacker: EntityIdentity);
#signal death(fatal_damage: float, old_health, killer: EntityIdentity);


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
@export var max_health: float = 100.0;


func _init() -> void:
	if Engine.is_editor_hint() and entity_identity:
		entity_identity.changed.connect(_on_entity_identity_changed);


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	AssertLib.assert_if_entity_identity_not_found(entity_identity);


func _get_configuration_warnings() -> PackedStringArray:
	return ConfigurationWarningLib.get_for_entity_identity(entity_identity);


func heal(amount: float = 0.0, healer: EntityIdentity = EntityIdentity.new()) -> void:
	var old_health: float = current_health;
	var new_health: float = clampf(old_health + amount, 0.0, max_health);

	if old_health == new_health: return;

	current_health = new_health;

	health_changed.emit(old_health, new_health, healer);
	healed.emit(amount, old_health, current_health, healer);


func damage(amount: float = 0.0, attacker: EntityIdentity = EntityIdentity.new()) -> void:
	var old_health: float = current_health;
	var new_health: float = clampf(old_health - amount, 0.0, max_health);

	if old_health == new_health: return;

	current_health = new_health;

	health_changed.emit(old_health, new_health, attacker);
	damaged.emit(amount, old_health, current_health, attacker);
	#if current_health <= 0.0: death.emit(amount, old_health, attacker);


func _on_entity_identity_changed() -> void:
	update_configuration_warnings();


## Called when the entity got healed and processed here to print debug information about what happened.
func _on_healed(amount: float, _old_health: float, _new_health: float, healer: EntityIdentity) -> void:
	print(
			"=== HEALING DEBUG ===\n" +
			"- Healer: %s\n" % healer.name +
			"- Receiver: %s\n" % entity_identity.name +
			"- Healing received: %s\n" % amount +
			"- Current health: %s / %s\n\n" % [current_health, max_health]
	);


## Called when the entity took damage and processed here to print debug information about what happened.
func _on_damaged(amount: float, _old_health: float, _new_health: float, attacker: EntityIdentity) -> void:
	print(
			"=== DAMAGE DEBUG ===\n" +
			"- Attacker: %s\n" % attacker.name +
			"- Attacked: %s\n" % entity_identity.name +
			"- Damage taken: %s\n" % amount +
			"- Current health: %s / %s\n\n" % [current_health, max_health]
	);


#func _on_death(fatal_damage: float, old_health: Variant, killer: EntityIdentity) -> void:
	#print(
			#"=== DEATH DEBUG ===\n" +
			#"- Killer: %s\n" % killer.name +
			#"- Deceased: %s\n" % entity_component.identity.name +
			#"- Health before death: %s\n" % old_health +
			#"- Fatal damage: %s\n\n" % fatal_damage
	#);
