class_name PlayableTestArcingProjectileWeapon1ComponentBullet
extends PlayableProjectileBullet


@onready var _splash_test: ShapeCast3D = %SplashTest;


func _on_collided(collision: KinematicCollision3D) -> void:
	print("Hit: ", collision.get_collider());

	# Still will detect anything behind something else.
	_splash_test.force_shapecast_update();

	for collision_index: int in range(_splash_test.get_collision_count()):
		var collider: Object = _splash_test.get_collider(collision_index);

		# The splash test only masks entities but let's add a check just in case.
		if not EntityComponent.is_object_an_entity(collider):
			continue;

		print("Splash detected this entity: ", collider);


func _on_life_duration_timer_timeout() -> void:
	queue_free();
