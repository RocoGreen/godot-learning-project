class_name PlayableTestProjectileWeapon1ComponentBullet
extends CharacterBody3D


var weapon: PlayableTestProjectileWeapon1Component;

var _collided: bool = false;


func _ready() -> void:
	add_collision_exception_with(weapon.playable);

	var old_scale: Vector3 = scale;

	global_transform = weapon._bullet_start_transform_anchor.global_transform;
	scale = old_scale;


func _physics_process(delta: float) -> void:
	if _collided: return;

	velocity = -global_basis.z.normalized() * weapon.bullet_travel_speed;

	var collision: KinematicCollision3D = move_and_collide(velocity * delta);

	if collision:
		var collider: Object = collision.get_collider();

		if EntityComponent.is_object_an_entity(collider):
			var collider_entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(collider);

			if weapon._mode == weapon._Mode.DAMAGE:
				_apply_damage_to_entity(collider_entity);

			elif weapon._mode == weapon._Mode.HEAL:
				_apply_healing_to_entity(collider_entity);

			queue_free();

		_collided = true;


func _apply_damage_to_entity(entity: PhysicsBody3D) -> void:
	var entity_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not entity_health_component: return;

	entity_health_component.damage(weapon.bullet_damage, weapon.playable_identity);


func _apply_healing_to_entity(entity: PhysicsBody3D) -> void:
	var entity_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not entity_health_component: return;

	entity_health_component.heal(weapon.bullet_healing, weapon.playable_identity);


func _on_life_duration_timer_timeout() -> void:
	queue_free();
