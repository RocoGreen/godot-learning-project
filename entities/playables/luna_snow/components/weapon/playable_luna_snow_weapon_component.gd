class_name PlayableLunaSnowWeaponComponent
extends Node3D


signal healed_someone(amount: float);

enum _ManualMode {
	HEALING,
	DAMAGE,
};

@export_group("Dependencies")
@export var luna_snow_identity: EntityIdentity;
@export var camera_component: PlayableCameraComponent;

@export_group("Settings")
@export var healing_per_shot: float = 60.0;
@export var damage_per_shot: float = 40.0;
@export var delay_between_shots: float = 0.2;
@export var recovery_delay_after_valley: float = 0.6;
@export var healing_or_damage_manual_mode: bool = false;
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var weapon_input_action: StringName = &"primary_fire";

@onready var bullet_start_transform_anchor_marker_3d: Marker3D = %BulletStartTransformAnchor;
@onready var bullet_ray_cast: PlayableHitscanBullet = %Bullet;

@onready var debug_draw: DebugDraw3D = %DebugDraw3D;

var _draw_line_end: Vector3 = Vector3.ZERO;

var _shooting_valley: bool = false;
var _in_recovery: bool = false;

var _manual_mode: _ManualMode = _ManualMode.HEALING;


func _process(_delta: float) -> void:
	if _draw_line_end == Vector3.ZERO: return;

	debug_draw.draw_line(
			debug_draw.to_local(bullet_start_transform_anchor_marker_3d.global_position),
			debug_draw.to_local(_draw_line_end),
			Color.SKY_BLUE,
			5.0
	);


func _physics_process(_delta: float) -> void:
	if GameState.in_game_input_disabled: 
		return;

	if Input.is_action_just_pressed(&"toggle_weapon_mode"):
		_toggle_manual_mode();

	if not Input.is_action_pressed(weapon_input_action): 
		return;

	if _shooting_valley or _in_recovery: 
		return;

	_shoot_valley();


func _shoot_valley() -> void:
	_shooting_valley = true;

	for loop_index: int in range(3):
		_shoot_bullet();

		await get_tree().create_timer(delay_between_shots).timeout;

	_shooting_valley = false;
	_in_recovery = true;

	await get_tree().create_timer(recovery_delay_after_valley).timeout;

	_in_recovery = false;


func _shoot_bullet() -> void:
	var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();

	if ray_to_get_what_player_aims_at_results.is_empty(): 
		return;

	var where_bullet_starts: Vector3 = bullet_start_transform_anchor_marker_3d.global_position;
	var where_bullet_ends: Vector3 = ray_to_get_what_player_aims_at_results.get("position");
	var hit_something: bool = bullet_ray_cast.launch(where_bullet_starts, where_bullet_ends);

	if not hit_something: 
		return;

	var target: PhysicsBody3D = bullet_ray_cast.get_collider() as PhysicsBody3D;
	var target_aimed_at_aim_point: Vector3 = bullet_ray_cast.get_collision_point();

	if target.is_in_group(&"entities"): 
		var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
		var target_identity: EntityIdentity = target_entity_component.identity;

		if healing_or_damage_manual_mode:
			if _manual_mode == _ManualMode.HEALING:
				_apply_healing_to_target(target);
			elif _manual_mode == _ManualMode.DAMAGE:
				_apply_damage_to_target(target);

		else:
			if target_identity.team == luna_snow_identity.team:
				_apply_healing_to_target(target);
			else:
				_apply_damage_to_target(target);

	_draw_line_end = target_aimed_at_aim_point;
	await get_tree().create_timer(0.1).timeout;
	_draw_line_end = Vector3.ZERO;


func _apply_healing_to_target(target: PhysicsBody3D) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_health: EntityHealthComponent = target_entity_component.health_component;

	if not target_health: return;

	var final_healing_done: float = target_health.heal(healing_per_shot, luna_snow_identity);

	if final_healing_done > 0.0:
		healed_someone.emit(final_healing_done);


func _apply_damage_to_target(target: PhysicsBody3D) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_health: EntityHealthComponent = target_entity_component.health_component;

	if not target_health: return;

	target_health.damage(damage_per_shot, luna_snow_identity);


func _toggle_manual_mode() -> void:
	if _manual_mode == _ManualMode.HEALING:
		_manual_mode = _ManualMode.DAMAGE;
		print("Luna Snow Weapon Damage Mode engaged !");

	elif _manual_mode == _ManualMode.DAMAGE:
		_manual_mode = _ManualMode.HEALING;
		print("Luna Snow Weapon Healing Mode engaged !");
