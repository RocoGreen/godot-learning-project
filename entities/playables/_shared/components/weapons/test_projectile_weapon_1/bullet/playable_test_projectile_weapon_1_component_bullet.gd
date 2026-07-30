class_name PlayableTestProjectileWeapon1ComponentBullet
extends CharacterBody3D


var weapon: PlayableTestProjectileWeapon1Component;

var _collided: bool = false;


func _ready() -> void:
	add_collision_exception_with(weapon.entity);
	
	var old_scale: Vector3 = scale;
	
	global_transform = weapon._bullet_start_transform_anchor.global_transform;
	scale = old_scale;


func _physics_process(delta: float) -> void:
	if _collided: return;
	
	velocity = -global_basis.z.normalized() * weapon.bullet_travel_speed;
	
	var collision := move_and_collide(velocity * delta) as KinematicCollision3D;
	
	if collision:
		var target: PhysicsBody3D = collision.get_collider();
		
		if target.is_in_group(&"entities"):
			if weapon._mode == weapon._Mode.DAMAGE:
				_apply_damage_to_target(target);
			
			elif weapon._mode == weapon._Mode.HEAL:
				_apply_healing_to_target(target);
			
			queue_free();
		
		_collided = true;


func _apply_damage_to_target(target: PhysicsBody3D) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity_or_assert(target);
	var target_health: EntityHealthComponent = target_entity_component.exp_health_component;
	
	if not target_health: return;
	
	target_health.damage(weapon.bullet_damage, weapon.entity_identity);


func _apply_healing_to_target(target: PhysicsBody3D) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity_or_assert(target);
	var target_health: EntityHealthComponent = target_entity_component.exp_health_component;
	
	if not target_health: return;
	
	target_health.heal(weapon.bullet_healing, weapon.entity_identity);


func _on_life_duration_timer_timeout() -> void:
	queue_free();
