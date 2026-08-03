@tool

class_name PlayableRotationByMouseComponent
extends Node


@export_group("Dependencies")
@export var entity: PhysicsBody3D:
	set(new_entity):
		entity = new_entity;
		
		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Settings")
@export var mouse_sensitivity: float = 0.001;

var _rotation_x: float = 0.0:
	set(new_rotation_x):
		_rotation_x = clampf(new_rotation_x, -PI / 2, PI / 2);

var _rotation_y: float = 0.0;


func _ready() -> void:
	if Engine.is_editor_hint(): return;
	
	AssertLib.assert_if_entity_not_found(entity);
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return;
	
	entity.basis = Basis(Quaternion(Vector3.UP, _rotation_y) * Quaternion(Vector3.RIGHT, _rotation_x));


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return;
	
	if event is InputEventMouseMotion:
		_rotation_x += -event.screen_relative.y * mouse_sensitivity;
		_rotation_y += -event.screen_relative.x * mouse_sensitivity;


func _get_configuration_warnings() -> PackedStringArray:
	return ConfigurationWarningLib.get_for_entity(entity);
