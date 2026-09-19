@tool

class_name PlayableRotationHandlingByMouseComponent
extends Node


@export_group("Dependencies")
@export var playable: CharacterBody3D:
	set(new_playable):
		playable = new_playable;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Settings")
@export var mouse_sensitivity: float = 0.001;

var _playable_rotation_x: float = 0.0:
	set(new_playable_rotation_x):
		_playable_rotation_x = clampf(new_playable_rotation_x, -PI / 2, PI / 2);

var _playable_rotation_y: float = 0.0;


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return;

	playable.basis = Basis(
			Quaternion(Vector3.UP, _playable_rotation_y) 
			* 
			Quaternion(Vector3.RIGHT, _playable_rotation_x)
	);


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return;

	if event is InputEventMouseMotion:
		_playable_rotation_x += -event.screen_relative.y * mouse_sensitivity;
		_playable_rotation_y += -event.screen_relative.x * mouse_sensitivity;


func _get_configuration_warnings() -> PackedStringArray:
	return ConfigurationWarningLibrary.get_for_playable(playable);
