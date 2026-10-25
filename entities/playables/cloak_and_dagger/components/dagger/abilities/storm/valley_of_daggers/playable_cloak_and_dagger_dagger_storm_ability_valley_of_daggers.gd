class_name PlayableCloakAndDaggerDaggerStormAbilityValleyOfDaggers
extends PlayableProjectileBullet


static var _PACKED_SCENE: PackedScene = load("res://entities/playables/cloak_and_dagger/components/dagger/abilities/storm/valley_of_daggers/playable_cloak_and_dagger_dagger_storm_ability_valley_of_daggers.tscn");


static func create(
	playable_cloak_and_dagger_to_exclude_from_collision: PlayableCloakAndDagger,
) -> PlayableCloakAndDaggerDaggerStormAbilityValleyOfDaggers:
	var valley: PlayableCloakAndDaggerDaggerStormAbilityValleyOfDaggers = _PACKED_SCENE.instantiate();

	valley.add_collision_exception_with(playable_cloak_and_dagger_to_exclude_from_collision);

	return valley;


func _init() -> void:
	collided.connect(_on_collided);


func _on_collided(_collision: KinematicCollision3D) -> void:
	queue_free();
