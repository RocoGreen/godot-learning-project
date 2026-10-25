class_name PlayableMercyPistolWeaponComponent
extends Node3D


signal unheld;

@export_group("Dependencies")
@export var playable_mercy: PlayableMercy;
@export var playable_mercy_identity: PlayableMercyIdentity;

@export_subgroup("Components")
@export var camera_component: PlayableCameraComponent;
@export var staff_weapon_component: PlayableMercyStaffWeaponComponent;
@export var ultimate_component: PlayableMercyUltimateComponent;

@export_group("Weapon Settings")
@export var default_weapon_held: bool = false;
@export var ammo: int = 25;
@export var time_seconds_to_reload: float = 1.4;
@export var delay_seconds_between_shots: float = 0.15;
@export var time_seconds_to_swap_to_weapon: float = 0.2;
@export var auto_reload_time_seconds_after_unhold: float = 1.4;

@export_group("Bullet Settings")
@export var bullet_damage_amount: float = 20.0;
@export var bullet_damages_any_entity: bool = false;
@export var bullet_travel_speed_in_meters_per_second: float = 50.0;
@export var bullet_travel_speed_in_meters_per_second_when_ulting: float = 100.0;
@export var bullet_life_duration_seconds_after_firing: float = 5.0;

@export_group("Input Actions Settings")
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_shoot: StringName = &"primary_fire";
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_reload: StringName = &"reload";

var _held: bool = false;
var _ammo: int;
var _swapping_to_weapon: bool = false;
var _swapped_to_this_weapon_this_frame: bool = false;

@onready var mesh_instance: MeshInstance3D = %MeshInstance;

@onready var bullet_start_position_anchor_marker_3d: Marker3D = %BulletStartPositionAnchor;

@onready var reload_time_timer: Timer = %ReloadTime;
@onready var delay_between_shots_timer: Timer = %DelayBetweenShots;
@onready var time_to_swap_to_weapon_timer: Timer = %TimeToSwapToWeaponTimer;
@onready var auto_reload_time_after_unhold: Timer = %AutoReloadTimeAfterUnhold;


func _ready() -> void:
	_held = default_weapon_held;
	_ammo = ammo;

	ultimate_component.activated.connect(_on_ultimate_activated);

	if not _held:
		mesh_instance.hide();


func _physics_process(_delta: float) -> void:
	if not _swapped_to_this_weapon_this_frame:
		if _held and Input.is_action_just_pressed(&"swap_weapon"):
			swap_to_staff_weapon();
			return;
	else:
		_swapped_to_this_weapon_this_frame = false;

	if not _held or _swapping_to_weapon: return;

	if not _is_reloading() and not ultimate_component.is_active():
		if _ammo <= 0 or Input.is_action_just_pressed(input_action_to_reload):
			_start_reloading();
			return;

	if not Input.is_action_pressed(input_action_to_shoot): return;
	if _is_delay_between_shots_ongoing(): return;
	if _is_reloading(): return;

	_create_then_fire_bullet();


func swap_to_this_weapon() -> void:
	_held = true;

	mesh_instance.show();

	_swapped_to_this_weapon_this_frame = true;

	time_to_swap_to_weapon_timer.start(time_seconds_to_swap_to_weapon);
	_swapping_to_weapon = true;

	if not auto_reload_time_after_unhold.is_stopped():
		auto_reload_time_after_unhold.stop();


func swap_to_staff_weapon() -> void:
	_held = false;
	mesh_instance.hide();

	if not time_to_swap_to_weapon_timer.is_stopped():
		time_to_swap_to_weapon_timer.stop();

	staff_weapon_component.swap_to_this_weapon();

	unheld.emit();


func _create_then_fire_bullet() -> void:
	var bullet: PlayableMercyPistolWeaponBullet = _create_bullet_and_get_it();
	var where_to_shoot_at: Vector3 = camera_component.get_position_to_look_at_aim_direction();

	var final_bullet_travel_speed_in_meters_per_second: float;
	
	if ultimate_component.is_active():
		final_bullet_travel_speed_in_meters_per_second = \
				bullet_travel_speed_in_meters_per_second_when_ulting;
	else:
		final_bullet_travel_speed_in_meters_per_second = bullet_travel_speed_in_meters_per_second;

	bullet.launch(
			bullet_start_position_anchor_marker_3d.global_position,
			where_to_shoot_at,
			final_bullet_travel_speed_in_meters_per_second,
	);

	if not ultimate_component.is_active():
		_ammo -= 1;
		print("Current Mercy's Pistol's ammo : ", _ammo, "/", ammo);

	_start_delay_between_shots();


func _create_bullet_and_get_it() -> PlayableMercyPistolWeaponBullet:
	var bullet: PlayableMercyPistolWeaponBullet = PlayableMercyPistolWeaponBullet.create(
			bullet_damage_amount,
			bullet_damages_any_entity,
			bullet_life_duration_seconds_after_firing,
			playable_mercy,
			playable_mercy_identity,
	);

	add_child(bullet);

	return bullet;


func _start_delay_between_shots() -> void:
	delay_between_shots_timer.start(delay_seconds_between_shots);


func _start_reloading() -> void:
	reload_time_timer.start(time_seconds_to_reload);
	
	if _ammo == 0:
		print("Mercy's Pistol's ammo is empty. Reloading...");
	else:
		print("Reloading Mercy's Pistol...");


func _reload() -> void:
	_ammo = ammo;
	print("Mercy's Pistol is now fully loaded !");


func _is_reloading() -> bool:
	if not reload_time_timer.is_stopped():
		return true;
	else:
		return false;


func _is_fully_loaded() -> bool:
	if _ammo >= ammo:
		return true;
	else:
		return false


func _is_delay_between_shots_ongoing() -> bool:
	if not delay_between_shots_timer.is_stopped():
		return true;
	else:
		return false;


func _on_held() -> void:
	if not auto_reload_time_after_unhold.is_stopped():
		auto_reload_time_after_unhold.stop();


func _on_unheld() -> void:
	if not _is_fully_loaded():
		auto_reload_time_after_unhold.start(auto_reload_time_seconds_after_unhold);


func _on_reload_time_timer_timeout() -> void:
	_reload();


func _on_auto_reload_time_after_unhold_timer_timeout() -> void:
	_reload();


func _on_ultimate_activated() -> void:
	_reload();


func _on_time_to_swap_to_weapon_timer_timeout() -> void:
	_swapping_to_weapon = false;
