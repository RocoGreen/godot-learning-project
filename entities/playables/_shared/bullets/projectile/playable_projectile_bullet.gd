class_name PlayableProjectileBullet
extends CharacterBody3D


signal launched;
signal collided(collision: KinematicCollision3D);
signal maximum_travel_distance_reached;

var _launched: bool = false;
var _maximum_travel_distance_got_reached: bool = false;
var _collided: bool = false;

var _affected_by_gravity: bool = false;

var _maximum_travel_distance: float = 0.0;
var _distance_traveled: float = 0.0;


func _physics_process(delta: float) -> void:
	if not _launched or _collided or _maximum_travel_distance_got_reached: return;

	var velocity_of_this_frame: Vector3 = velocity * delta;

	if _affected_by_gravity: 
		velocity_of_this_frame += get_gravity() * delta;

	elif _maximum_travel_distance != 0.0:
		var distance_that_will_be_traveled_this_frame: float = velocity_of_this_frame.length();

		if (_distance_traveled + distance_that_will_be_traveled_this_frame) >= _maximum_travel_distance:
			velocity_of_this_frame = \
					velocity.normalized() * (_maximum_travel_distance - _distance_traveled);
			_maximum_travel_distance_got_reached = true;

	var collision: KinematicCollision3D = move_and_collide(velocity_of_this_frame);

	_distance_traveled += velocity_of_this_frame.length();

	if collision:
		collided.emit(collision);
		_collided = true;

	if _maximum_travel_distance_got_reached:
		maximum_travel_distance_reached.emit();


func launch(
		from_global_position: Vector3, to_global_position: Vector3, at_speed: float,
		affected_by_gravity: bool = false, with_up_tilt: float = 0.0,
		maximum_travel_distance: float = 0.0,
) -> void:
	look_at_from_position(from_global_position, to_global_position);

	velocity = -global_basis.z.normalized() * at_speed;
	velocity.y += with_up_tilt;

	_launched = true;
	_affected_by_gravity = affected_by_gravity;

	if maximum_travel_distance != 0.0:
		_maximum_travel_distance = maximum_travel_distance;

	launched.emit();
