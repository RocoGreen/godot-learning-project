@warning_ignore("empty_file")

#extends Node
#
#
#@export_group("Dependencies")
#@export var luna_snow_identity: EntityIdentity;
#@export var camera_component: PlayableCameraComponent;
#
#@export var weapon_component: PlayableLunaSnowWeaponComponent;
#@export var clap_ability_component: PlayableLunaSnowClapAbilityComponent;
#@export var ultimate_component: PlayableLunaSnowUltimateComponent;
#
#@export_group("Settings")
#@export_range(0, 100) var percentage_from_healing: int = 30;
#@export var allow_flake_for_any_entity: bool = false;
#@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_use: StringName = &"ability_1";
#
#var _flaked_entity_health_component: EntityHealthComponent;
#
#
#func _ready() -> void:
	#weapon_component.healed_someone.connect(_on_weapon_healed_someone);
	#clap_ability_component.healed_someone.connect(_on_clap_ability_healed_someone);
	#ultimate_component.healed_someone.connect(_on_ultimate_healed_someone);
#
#
#func _physics_process(_delta: float) -> void:
	#if GameState.in_game_input_disabled: return;
	#if not Input.is_action_just_pressed(input_action_to_use): return;
#
	## If an entity is already flaked and the ability input action have been pressed, we want to
	## revoke the flake. We only want to do that so let's stop the function after we're done.
	#if _flaked_entity_health_component:
		#_revoke_flake();
#
	#_flake_entity_player_aims_at();
#
#
#func _flake_entity_player_aims_at() -> void:
	## A request to flake an entity have been requested ! Let's try to flake one then !
#
	## We want to flake the entity the player is aiming at so let's get it.
	#var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();
#
	## If the player isn't aiming at an entity, there is no one to flake.
	#if ray_to_get_what_player_aims_at_results.is_empty(): return;
#
	#var target: PhysicsBody3D = ray_to_get_what_player_aims_at_results.collider as PhysicsBody3D;
#
	## If the ray hit something/someone that isn't an entity like an obstacle, then there is no 
	## one to flake. 
	#if not target.is_in_group(&"entities"): return;
#
	## Okay, we have the entity ! Now, let's check if it is eligible for flake.
#
	#var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	#var target_identity: EntityIdentity = target_entity_component.identity;
	#var target_health: EntityHealthComponent = target_entity_component.health_component;
#
	## If the target doesn't have a health component, there is nothing for the flake to heal.
	#if not target_health: return;
	## If flake is not allowed for any entity and the target is not in Luna Snow's team, the target
	## shouldn't get the flake. Only allies can be flaked.
	#if not allow_flake_for_any_entity and target_identity.team != luna_snow_identity.team: return;
#
	## All the checks passed ! The target will receive the shared healing (flake) !
	#_flaked_entity_health_component = target_health;
	#print("%s has been flaked !" % target_entity_component.identity.name);
#
#
#func _revoke_flake() -> void:
	#_flaked_entity_health_component = null;
	#print("Revoked flake !");
	#return;
#
#
#func _heal_flaked_entity(real_amount_healed: float) -> void:
	## Of course, let's be sure first there is a flaked entity first.
	#if not _flaked_entity_health_component: return;
#
	## If there is, it's all good !
	## All there is to do now is to calculate the shared healing number then heal the flaked entity.
	#var healing_to_do: float = _what_is_percentage_of(percentage_from_healing, real_amount_healed);
	#_flaked_entity_health_component.heal(healing_to_do, luna_snow_identity);
#
#
#func _what_is_percentage_of(percentage: int, of: float) -> float:
	#return (percentage * of) / 100;
#
#
#func _on_weapon_healed_someone(amount: float) -> void:
	#_heal_flaked_entity(amount);
#
#
#func _on_clap_ability_healed_someone(amount: float) -> void:
	#_heal_flaked_entity(amount);
#
#
#func _on_ultimate_healed_someone(amount: float) -> void:
	#_heal_flaked_entity(amount);
