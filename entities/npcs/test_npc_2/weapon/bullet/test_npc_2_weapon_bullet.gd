class_name TestNPC2WeaponBullet
extends CharacterBody3D


var _launched: bool = false;

var _damage_to_entity_hit: float;
var _shooter_identity: EntityIdentity = EntityIdentity.new();


func _physics_process(delta: float) -> void:
	var collision: KinematicCollision3D = move_and_collide(velocity * delta);

	if collision:
		var target_hit: PhysicsBody3D = collision.get_collider();

		if target_hit.is_in_group(&"entities"):
			_apply_damage_to_target_entity(target_hit);

		queue_free();


func _apply_damage_to_target_entity(entity: PhysicsBody3D) -> void:
	var entity_entity_component: EntityComponent = EntityComponent.from_entity(entity);
	var entity_health_component: EntityHealthComponent = entity_entity_component.health_component;

	if not entity_health_component:
		return;

	entity_health_component.damage(_damage_to_entity_hit, _shooter_identity);


func launch(
		from: Vector3, at_direction: Vector3, at_speed: float, 
		bullet_damage: float, life_duration_in_seconds_after_launch: float,
		shooter_identity: EntityIdentity
) -> void:
	global_position = from;

	velocity = at_direction * at_speed;

	_damage_to_entity_hit = bullet_damage;
	_shooter_identity = shooter_identity;
	_launched = true;

	await get_tree().create_timer(life_duration_in_seconds_after_launch).timeout;

	queue_free();
