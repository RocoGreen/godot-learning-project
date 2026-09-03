class_name TestNPC2Weapon
extends Node3D

@export var test_npc_2_identity: EntityIdentity;

@export var bullet: PackedScene;
@export var bullet_damage: float = 20.0;
@export var bullet_travel_speed_meters_per_second: float = 20.0;
@export var bullet_life_duration_in_seconds_after_launch: float = 5.0;

@onready var bullet_start_transform_anchor_marker_3d: Marker3D = $BulletStartTransformAnchor;


func _ready() -> void:
	_start_bullet_shoot_interval_loop();


func _start_bullet_shoot_interval_loop() -> void:
	_fire_bullet();

	await get_tree().create_timer(0.5).timeout;

	_start_bullet_shoot_interval_loop();


func _fire_bullet() -> void:
	var bullet_to_launch: TestNPC2WeaponBullet = bullet.instantiate();

	add_child(bullet_to_launch);

	bullet_to_launch.launch(
			bullet_start_transform_anchor_marker_3d.global_position,
			-bullet_start_transform_anchor_marker_3d.global_basis.z.normalized(),
			bullet_travel_speed_meters_per_second,
			bullet_damage,
			bullet_life_duration_in_seconds_after_launch,
			test_npc_2_identity
	);
