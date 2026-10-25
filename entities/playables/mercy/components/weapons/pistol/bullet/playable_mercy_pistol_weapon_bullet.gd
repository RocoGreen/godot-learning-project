class_name PlayableMercyPistolWeaponBullet
extends PlayableProjectileBullet


static var _PACKED_SCENE: PackedScene = load("res://entities/playables/mercy/components/weapons/pistol/bullet/playable_mercy_pistol_weapon_bullet.tscn");

var _damage_amount_to_entity_hit: float;
var _damage_any_entity: bool;
var _life_duration_seconds_after_firing: float;

var _playable_mercy_identity: PlayableMercyIdentity;

@onready var life_duration_time_after_firing_timer: Timer = %LifeDurationTimeAfterFiring;


static func create(
		damage_amount_to_entity_hit: float,
		damage_any_entity: bool,
		life_duration_seconds_after_firing: float,
		playable_mercy_to_exclude_from_collision: PlayableMercy, 
		playable_mercy_identity: PlayableMercyIdentity,
) -> PlayableMercyPistolWeaponBullet:
	var bullet: PlayableMercyPistolWeaponBullet = _PACKED_SCENE.instantiate();

	bullet.add_collision_exception_with(playable_mercy_to_exclude_from_collision);

	bullet._damage_amount_to_entity_hit = damage_amount_to_entity_hit;
	bullet._damage_any_entity = damage_any_entity;
	bullet._life_duration_seconds_after_firing = life_duration_seconds_after_firing;

	bullet._playable_mercy_identity = playable_mercy_identity;

	return bullet;


func _on_launched() -> void:
	life_duration_time_after_firing_timer.start(_life_duration_seconds_after_firing);


func _on_collided(collision: KinematicCollision3D) -> void:
	var collider: Object = collision.get_collider();

	if not EntityComponent.is_object_an_entity(collider): return;

	var entity_to_damage: PhysicsBody3D = EntityComponent.cast_object_to_entity(collider);
	var entity_to_damage_identity: EntityIdentity = EntityIdentity.from_entity(entity_to_damage);
	var entity_to_damage_health_component := EntityHealthComponent.from_entity(entity_to_damage);

	if not entity_to_damage_identity: return;
	if entity_to_damage_identity.team == null: return;
	if not entity_to_damage_health_component: return;

	if not _damage_any_entity and entity_to_damage_identity.team == _playable_mercy_identity.team:
		return;

	entity_to_damage_health_component.damage(_damage_amount_to_entity_hit, _playable_mercy_identity);

	queue_free();


func _on_life_duration_time_after_firing_timer_timeout() -> void:
	queue_free();
