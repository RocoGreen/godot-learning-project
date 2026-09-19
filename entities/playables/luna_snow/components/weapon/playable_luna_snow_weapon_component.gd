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

@onready var bullet_start_position_anchor_marker_3d: Marker3D = %BulletStartPositionAnchor;
@onready var bullet_ray_cast: PlayableHitscanBullet = %Bullet;

@onready var debug_draw: DebugDraw3D = %DebugDraw3D;

var _draw_line_end: Vector3 = Vector3.ZERO;

var _shooting_valley: bool = false;
var _in_recovery: bool = false;

var _manual_mode: _ManualMode = _ManualMode.HEALING;


func _process(_delta: float) -> void:
	if _draw_line_end == Vector3.ZERO: return;

	debug_draw.draw_line(
			debug_draw.to_local(bullet_start_position_anchor_marker_3d.global_position),
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

	if ray_to_get_what_player_aims_at_results.is_empty(): return;

	var where_bullet_starts: Vector3 = bullet_start_position_anchor_marker_3d.global_position;
	var where_bullet_ends: Vector3 = ray_to_get_what_player_aims_at_results.get("position");
	var hit_something: bool = bullet_ray_cast.launch(where_bullet_starts, where_bullet_ends);

	if not hit_something: return;

	var what_player_aims_at: Object = bullet_ray_cast.get_collider();
	var aim_point_on_what_player_aims_at: Vector3 = bullet_ray_cast.get_collision_point();

	if EntityComponent.is_object_an_entity(what_player_aims_at):
		var entity_to_heal_or_damage: Node = EntityComponent.cast_object_to_entity(what_player_aims_at);
		var entity_to_heal_or_damage_identity := EntityIdentity.from_entity(entity_to_heal_or_damage);
		
		if not entity_to_heal_or_damage_identity: return;

		if healing_or_damage_manual_mode:
			if _manual_mode == _ManualMode.HEALING:
				_apply_healing_to_entity(entity_to_heal_or_damage);
			elif _manual_mode == _ManualMode.DAMAGE:
				_apply_damage_to_entity(entity_to_heal_or_damage);

		else:
			if entity_to_heal_or_damage_identity.team == luna_snow_identity.team:
				_apply_healing_to_entity(entity_to_heal_or_damage);
			else:
				_apply_damage_to_entity(entity_to_heal_or_damage);

	_draw_line_end = aim_point_on_what_player_aims_at;
	await get_tree().create_timer(0.1).timeout;
	_draw_line_end = Vector3.ZERO;


func _apply_healing_to_entity(entity: Node) -> void:
	var target_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not target_health_component: return;

	var final_healing_done: float = target_health_component.heal(healing_per_shot, luna_snow_identity);

	if final_healing_done > 0.0:
		healed_someone.emit(final_healing_done);


func _apply_damage_to_entity(entity: Node) -> void:
	var target_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not target_health_component: return;

	target_health_component.damage(damage_per_shot, luna_snow_identity);


func _toggle_manual_mode() -> void:
	if _manual_mode == _ManualMode.HEALING:
		_manual_mode = _ManualMode.DAMAGE;
		print("Luna Snow Weapon Damage Mode engaged !");

	elif _manual_mode == _ManualMode.DAMAGE:
		_manual_mode = _ManualMode.HEALING;
		print("Luna Snow Weapon Healing Mode engaged !");
