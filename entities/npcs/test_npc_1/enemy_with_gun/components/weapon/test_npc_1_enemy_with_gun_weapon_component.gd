class_name TestNPC1EnemyWithGunWeaponComponent
extends Node3D


@export_group("Dependencies")
@export var test_npc_1_enemy_with_gun: TestNPC1EnemyWithGun;
@export var test_npc_1_enemy_with_gun_identity: TestNPC1EnemyWithGunIdentity;

@export_group("Weapon Settings")
@export var fire_rate_per_second: float = 0.5;

@export_group("Bullet Settings")
@export var bullet_damage_amount_per_entity_hit: float = 20.0;
@export var bullet_travel_speed_in_meters_per_second: float = 20.0;
@export var bullet_life_duration_in_seconds_after_launch: float = 5.0;

@onready var fire_rate_per_second_timer: Timer = %FireRatePerSecondTimer;
@onready var bullet_start_transform_anchor_marker_3d: Marker3D = %BulletSpawnTransformAnchorMarker3D;


func _ready() -> void:
	fire_rate_per_second_timer.start(fire_rate_per_second);


func _create_bullet_and_get_it() -> TestNPC1EnemyWithGunWeaponBullet:
	var bullet: TestNPC1EnemyWithGunWeaponBullet = TestNPC1EnemyWithGunWeaponBullet.create(
			bullet_damage_amount_per_entity_hit,
			bullet_life_duration_in_seconds_after_launch,
			test_npc_1_enemy_with_gun_identity,
			test_npc_1_enemy_with_gun,
	);

	return bullet;


func _fire_bullet() -> void:
	var bullet: TestNPC1EnemyWithGunWeaponBullet = _create_bullet_and_get_it();

	add_child(bullet);

	bullet.launch(
			_get_global_position_to_spawn_bullet_at(),
			_get_direction_vector_to_launch_bullet_at(),
			bullet_travel_speed_in_meters_per_second,
	);


func _get_global_position_to_spawn_bullet_at() -> Vector3:
	return bullet_start_transform_anchor_marker_3d.global_position;


func _get_direction_vector_to_launch_bullet_at() -> Vector3:
	# Forward vector of the anchor.
	return -bullet_start_transform_anchor_marker_3d.global_basis.z.normalized();


func _on_fire_rate_per_second_timer_timeout() -> void:
	_fire_bullet();
