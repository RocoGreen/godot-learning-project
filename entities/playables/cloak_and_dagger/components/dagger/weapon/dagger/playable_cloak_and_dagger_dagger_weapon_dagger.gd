class_name PlayableCloakAndDaggerDaggerWeaponDagger
extends CharacterBody3D


static var _PACKED_SCENE: PackedScene = load("res://entities/playables/cloak_and_dagger/components/dagger/weapon/dagger/playable_cloak_and_dagger_dagger_weapon_dagger.tscn");

var _global_position_to_spawn: Vector3;
var _direction_at_spawn: Vector3;

var _heal_per_entity_hit: float;
var _impact_explosion_healing_amount: float;

var _travel_speed_in_meters_per_second: float;

var _entity_to_travel_at_center_position_anchor: Marker3D;

var _playable_cloak_and_dagger_identity: EntityIdentity;

var _launched: bool = false;

@onready var shape_cast_3d_for_impact_explosion: ShapeCast3D = %ShapeCast3DForImpactExplosion;


static func create(
		global_position_to_spawn: Vector3,
		direction_at_spawn: Vector3,

		heal_per_entity_hit: float,
		impact_explosion_healing_amount: float,

		travel_speed_in_meters_per_second: float,

		entity_to_travel_at_center_position_anchor: Marker3D,

		playable_cloak_and_dagger_to_exclude_from_collision: PlayableCloakAndDagger,
		playable_cloak_and_dagger_identity: EntityIdentity,
) -> PlayableCloakAndDaggerDaggerWeaponDagger:
	var dagger: PlayableCloakAndDaggerDaggerWeaponDagger = _PACKED_SCENE.instantiate();

	dagger._global_position_to_spawn = global_position_to_spawn;
	dagger._direction_at_spawn = direction_at_spawn;

	dagger._heal_per_entity_hit = heal_per_entity_hit;
	dagger._impact_explosion_healing_amount = impact_explosion_healing_amount;

	dagger._travel_speed_in_meters_per_second = travel_speed_in_meters_per_second;

	dagger._entity_to_travel_at_center_position_anchor = entity_to_travel_at_center_position_anchor;

	dagger._playable_cloak_and_dagger_identity = playable_cloak_and_dagger_identity;

	dagger.add_collision_exception_with(playable_cloak_and_dagger_to_exclude_from_collision);

	return dagger;


func _physics_process(delta: float) -> void:
	if not _launched: return;

	velocity = velocity.lerp(global_position.direction_to(_entity_to_travel_at_center_position_anchor.global_position), 0.04);
	print("Actual: ", velocity, " - Target: ", global_position.direction_to(_entity_to_travel_at_center_position_anchor.global_position));
	var collision: KinematicCollision3D = move_and_collide((velocity * _travel_speed_in_meters_per_second) * delta);

	if collision:
		for collision_index: int in range(collision.get_collision_count()):
			var collider: Object = collision.get_collider(collision_index);

			if EntityComponent.is_object_an_entity(collider):
				var collider_entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(collider);
				_apply_healing_to_entity(collider_entity);

		shape_cast_3d_for_impact_explosion.force_shapecast_update();

		for collision_index: int in range(shape_cast_3d_for_impact_explosion.get_collision_count()):
			var collider: Object = shape_cast_3d_for_impact_explosion.get_collider(collision_index);

			if EntityComponent.is_object_an_entity(collider):
				var collider_entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(collider);
				_apply_healing_explosion_to_entity(collider_entity);

		queue_free();


func launch() -> void:
	_launched = true;

	look_at_from_position(_global_position_to_spawn, _direction_at_spawn);
	velocity = -global_basis.z.normalized();


func _apply_healing_to_entity(entity: PhysicsBody3D) -> void:
	var entity_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not entity_health_component: return;

	entity_health_component.heal(_heal_per_entity_hit, _playable_cloak_and_dagger_identity);


func _apply_healing_explosion_to_entity(entity: PhysicsBody3D) -> void:
	var entity_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not entity_health_component: return;

	entity_health_component.heal(_impact_explosion_healing_amount, _playable_cloak_and_dagger_identity);
