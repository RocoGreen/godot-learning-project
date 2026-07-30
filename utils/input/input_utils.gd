class_name InputUtils
extends RefCounted


static func get_basic_movement_inputs_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO;
	
	if not (
			Input.is_action_pressed(&"move_left") \
			and \
			Input.is_action_pressed(&"move_right")
	):
		if Input.is_action_pressed(&"move_left"):
			direction.x = -Input.get_action_strength(&"move_left");
		
		elif Input.is_action_pressed(&"move_right"):
			direction.x = Input.get_action_strength(&"move_right");
	
	if not (
			Input.is_action_pressed(&"move_forward") \
			and \
			Input.is_action_pressed(&"move_backward")
	):
		if Input.is_action_pressed(&"move_forward"):
			direction.y = -Input.get_action_strength(&"move_forward");
		
		elif Input.is_action_pressed(&"move_backward"):
			direction.y = Input.get_action_strength(&"move_backward");
	
	return direction;
