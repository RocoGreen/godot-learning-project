class_name PlayableMercyUltimateComponent
extends Node


signal activating;
signal activated;

@export_group("Ultimate Settings")
@export var time_seconds_to_activate: float = 0.5;
@export var duration_seconds: float = 8.0;
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_activate: StringName = &"ultimate";

var _activating: bool = false:
	get = is_activating;

var _active: bool = false:
	get = is_active;

@onready var time_to_activate_timer: Timer = %TimeToActivateTimer;
@onready var duration_time_timer: Timer = %DurationTimeTimer;


func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed(input_action_to_activate): return;
	if is_active(): return;

	_start_activation();


func is_activating() -> bool:
	return _activating;


func is_active() -> bool:
	return _active;


func _start_activation() -> void:
	time_to_activate_timer.start(time_seconds_to_activate);
	_activating = true;
	activating.emit();

	print("Mercy's Ultimate is activating...");


func _activate() -> void:
	_activating = false;

	duration_time_timer.start(duration_seconds);
	_active = true;
	activated.emit();

	print("Mercy's Ultimate is now active !");


func _end() -> void:
	_active = false;

	print("Mercy's Ultimate ended !");


func _on_time_to_activate_timer_timeout() -> void:
	_activate();


func _on_duration_time_timer_timeout() -> void:
	_end();
