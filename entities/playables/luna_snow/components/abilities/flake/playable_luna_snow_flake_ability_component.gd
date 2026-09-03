extends Node


@export_group("Dependencies")
@export var luna_snow_identity: EntityIdentity;
@export var camera_component: PlayableCameraComponent;

@export var weapon_component: PlayableLunaSnowWeaponComponent;
@export var clap_ability_component: PlayableLunaSnowClapAbilityComponent;
@export var ultimate_component: PlayableLunaSnowUltimateComponent;

@export_group("Settings")
@export_range(0, 100) var percentage_from_healing: int = 30;
@export var allow_flake_for_any_entity: bool = false;
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_use: StringName = &"ability_1";

var _flaked_entity_health_component: EntityHealthComponent;


func _ready() -> void:
	weapon_component.healed_someone.connect(_on_weapon_healed_someone);
	clap_ability_component.healed_someone.connect(_on_clap_ability_healed_someone);
	ultimate_component.healed_someone.connect(_on_ultimate_healed_someone);


func _physics_process(_delta: float) -> void:
	if GameState.in_game_input_disabled: return;
	if not Input.is_action_just_pressed(input_action_to_use): return;

	if _flaked_entity_health_component:
		_revoke_flake();

	_flake_entity_player_aims_at();


func _flake_entity_player_aims_at() -> void:
	var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();

	if ray_to_get_what_player_aims_at_results.is_empty(): return;

	var target: PhysicsBody3D = ray_to_get_what_player_aims_at_results.collider as PhysicsBody3D;

	if not target.is_in_group(&"entities"): return;

	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_identity: EntityIdentity = target_entity_component.identity;
	var target_health: EntityHealthComponent = target_entity_component.health_component;

	if not target_health: return;
	if not allow_flake_for_any_entity and target_identity.team != luna_snow_identity.team: return;

	_flaked_entity_health_component = target_health;
	print("%s has been flaked !" % target_entity_component.identity.name);


func _revoke_flake() -> void:
	_flaked_entity_health_component = null;
	print("Revoked flake !");
	return;


func _heal_flaked_entity(real_amount_healed: float) -> void:
	if not _flaked_entity_health_component: return;

	var healing_to_do: float = _what_is_percentage_of(percentage_from_healing, real_amount_healed);
	_flaked_entity_health_component.heal(healing_to_do, luna_snow_identity);


func _what_is_percentage_of(percentage: int, of: float) -> float:
	return (percentage * of) / 100;


func _on_weapon_healed_someone(amount: float) -> void:
	_heal_flaked_entity(amount);


func _on_clap_ability_healed_someone(amount: float) -> void:
	_heal_flaked_entity(amount);


func _on_ultimate_healed_someone(amount: float) -> void:
	_heal_flaked_entity(amount);
