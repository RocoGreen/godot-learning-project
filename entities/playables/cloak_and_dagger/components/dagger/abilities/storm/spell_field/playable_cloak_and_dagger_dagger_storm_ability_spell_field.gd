class_name PlayableCloakAndDaggerDaggerStormAbilitySpellField
extends ShapeCast3D


signal ended;

static var _PACKED_SCENE: PackedScene = load("res://entities/playables/cloak_and_dagger/components/dagger/abilities/storm/spell_field/playable_cloak_and_dagger_dagger_storm_ability_spell_field.tscn");

var _burst_heal_amount_on_spawn: float;
var _healing_amount_per_second: float;

var _duration_seconds: float;
var _spherical_hitbox_radius_meters: float;

var _playable_cloak_and_dagger_identity: PlayableCloakAndDaggerIdentity;

var _just_spawned: bool = false;
var _spawned: bool = false;

@onready var duration_timer: Timer = %DurationTimer;

@onready var mesh_instance_3d: MeshInstance3D = %MeshInstance3D;
@onready var mesh_instance_3d_shape: SphereMesh = mesh_instance_3d.mesh as SphereMesh;


static func create(
		burst_heal_amount_on_spawn: float,
		healing_amount_per_second: float,

		duration_seconds: float,
		spherical_hitbox_radius_meters: float,

		playable_cloak_and_dagger_identity: PlayableCloakAndDaggerIdentity,
) -> PlayableCloakAndDaggerDaggerStormAbilitySpellField:
	var spell_field: PlayableCloakAndDaggerDaggerStormAbilitySpellField = _PACKED_SCENE.instantiate();

	spell_field._burst_heal_amount_on_spawn = burst_heal_amount_on_spawn;
	spell_field._healing_amount_per_second = healing_amount_per_second;

	spell_field._duration_seconds = duration_seconds;
	spell_field._spherical_hitbox_radius_meters = spherical_hitbox_radius_meters;

	spell_field._playable_cloak_and_dagger_identity = playable_cloak_and_dagger_identity;

	return spell_field;


func _ready() -> void:
	set_visible(false);


func _physics_process(delta: float) -> void:
	for collision_index: int in range(get_collision_count()):
		var collider: Object = get_collider(collision_index);

		if EntityComponent.is_object_an_entity(collider):
			var collider_entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(collider);
			
			if _just_spawned:
				_apply_burst_heal_to_entity(collider_entity);
			else:
				_apply_healing_per_second_to_entity(collider_entity, delta);

	if _just_spawned:
		_just_spawned = false;


func spawn(global_position_to_spawn: Vector3) -> void:
	_setup_shape_and_mesh_instance_3d_shape_from_hitbox_radius();

	set_global_position(global_position_to_spawn);
	set_enabled(true);
	set_visible(true);

	_just_spawned = true;
	_spawned = true;

	duration_timer.start(_duration_seconds);


func _setup_shape_and_mesh_instance_3d_shape_from_hitbox_radius() -> void:
	(shape as SphereShape3D).radius = _spherical_hitbox_radius_meters;

	mesh_instance_3d_shape.radius = _spherical_hitbox_radius_meters;
	mesh_instance_3d_shape.height = _spherical_hitbox_radius_meters * 2.0;


func _apply_burst_heal_to_entity(entity: PhysicsBody3D) -> void:
	var entity_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not entity_health_component: return;

	entity_health_component.heal(
			_burst_heal_amount_on_spawn, 
			_playable_cloak_and_dagger_identity,
	);


func _apply_healing_per_second_to_entity(entity: PhysicsBody3D, delta: float) -> void:
	var entity_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not entity_health_component: return;

	entity_health_component.heal(
			_healing_amount_per_second * delta, 
			_playable_cloak_and_dagger_identity,
	);


func _on_duration_timer_timeout() -> void:
	ended.emit();
	queue_free();
