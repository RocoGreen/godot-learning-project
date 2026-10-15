class_name TestNPC1EnemyWithGunWeaponBullet
extends CharacterBody3D


static var _PACKED_SCENE: PackedScene = load("res://entities/npcs/test_npc_1/enemy_with_gun/components/weapon/bullet/test_npc_1_enemy_with_gun_weapon_bullet.tscn");

var _damage_amount_per_entity_hit: float;
var _life_duration_in_seconds_after_launch: float;
var _test_npc_1_enemy_with_gun_identity: TestNPC1EnemyWithGunIdentity;

var _launched: bool = false;

@onready var life_duration_timer: Timer = %LifeDurationTimer;


static func create(
		damage_amount_per_entity_hit: float,
		life_duration_in_seconds_after_launch: float,

		test_npc_1_enemy_with_gun_identity: TestNPC1EnemyWithGunIdentity,
		test_npc_1_enemy_with_gun_to_exclude_from_collision: TestNPC1EnemyWithGun,
) -> TestNPC1EnemyWithGunWeaponBullet:
	var bullet: TestNPC1EnemyWithGunWeaponBullet = _PACKED_SCENE.instantiate();

	bullet._damage_amount_per_entity_hit = damage_amount_per_entity_hit;
	bullet._life_duration_in_seconds_after_launch = life_duration_in_seconds_after_launch;
	
	bullet._test_npc_1_enemy_with_gun_identity = test_npc_1_enemy_with_gun_identity;

	bullet.add_collision_exception_with(test_npc_1_enemy_with_gun_to_exclude_from_collision);

	return bullet;


func _physics_process(delta: float) -> void:
	var collision: KinematicCollision3D = move_and_collide(velocity * delta);

	if collision:
		for collision_index: int in range(collision.get_collision_count()):
			var collider: Object = collision.get_collider(collision_index);

			if EntityComponent.is_object_an_entity(collider):
				var collider_entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(collider);
				_apply_damage_to_entity(collider_entity);

		queue_free();


func launch(
		global_position_to_spawn_at: Vector3,
		at_direction_vector: Vector3,
		at_speed_in_meters_per_second: float,
) -> void:
	set_global_position(global_position_to_spawn_at);
	set_velocity(at_direction_vector * at_speed_in_meters_per_second);

	_launched = true;
	life_duration_timer.start(_life_duration_in_seconds_after_launch);


func _apply_damage_to_entity(entity: PhysicsBody3D) -> void:
	var entity_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not entity_health_component: return;

	entity_health_component.damage(
			_damage_amount_per_entity_hit, 
			_test_npc_1_enemy_with_gun_identity,
	);


func _on_life_duration_timer_timeout() -> void:
	queue_free();
