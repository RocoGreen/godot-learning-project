class_name PlayableProjectileBullet
extends CharacterBody3D


signal collided(collision: KinematicCollision3D);

var _launched: bool = false;
var _affected_by_gravity: bool = false;
var _collided: bool = false;


func _physics_process(delta: float) -> void:
	if not _launched or _collided: return;

	if _affected_by_gravity: 
		velocity += get_gravity() * delta;

	var collision: KinematicCollision3D = move_and_collide(velocity * delta);

	if collision:
		collided.emit(collision);
		_collided = true;


func launch(
		from_global_position: Vector3, to_global_position: Vector3, at_speed: float,
		affected_by_gravity: bool = false, with_up_tilt: float = 0.0
) -> void:
	look_at_from_position(from_global_position, to_global_position);

	velocity = -global_basis.z.normalized() * at_speed;
	velocity.y += with_up_tilt;

	_launched = true;
	_affected_by_gravity = affected_by_gravity;
