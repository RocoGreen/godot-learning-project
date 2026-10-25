class_name PlayableMercyRegenerationPassiveAbilityComponent
extends Node


@export_group("Dependencies")
@export var playable_mercy_identity: PlayableMercyIdentity;

@export_subgroup("Components")
@export var health_component: EntityHealthComponent;
@export var ultimate_component: PlayableMercyUltimateComponent;

@export_group("Passive Ability Settings")
@export var healing_amount_per_second: float = 20.0;
@export var delay_seconds_to_activate_after_no_damage_taken: float = 3.0;

var _activation_with_delay_ongoing: bool = false:
	set = _set_activation_with_delay_ongoing,
	get = _is_activation_with_delay_ongoing;

var _active: bool = false:
	set = _set_active,
	get = _is_active;

@onready var delay_to_activate_timer: Timer = %DelayToActivateTimer;


func _ready() -> void:
	health_component.damaged.connect(_on_damage_taken);
	ultimate_component.activated.connect(_on_ultimate_activated);


func _process(delta: float) -> void:
	# If Mercy's ultimate is active then we want to constantly regenerate without any interruption.
	if ultimate_component.is_active():
		_apply_healing(delta);

	elif _is_active():
		if not health_component.is_maximum_health():
			# If the regeneration is currently active, let's apply the healing for this frame !
			_apply_healing(delta);

		else:
			# Though, if the maximum health is reached, there is no reason to regenerate anymore so
			# let's deactivate it.
			_deactivate();

	elif not _is_activation_with_delay_ongoing():
		if not health_component.is_maximum_health():
			_activate_with_delay();

	elif health_component.is_maximum_health():
		_cancel_activation_with_delay();


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed() and event.physical_keycode == Key.KEY_TAB:
			health_component.damage(10.0, playable_mercy_identity);


func _activate_with_delay() -> void:
	delay_to_activate_timer.start(delay_seconds_to_activate_after_no_damage_taken);
	_set_activation_with_delay_ongoing(true);


func _cancel_activation_with_delay() -> void:
	delay_to_activate_timer.stop();
	_set_activation_with_delay_ongoing(false);


func _activate_after_activation_delay() -> void:
	if not health_component.is_maximum_health():
		_activate();

	_set_activation_with_delay_ongoing(false);


func _activate() -> void:
	_set_active(true);


func _apply_healing(delta: float) -> void:
	health_component.heal(healing_amount_per_second * delta, playable_mercy_identity);


func _deactivate() -> void:
	_set_active(false);


func _on_damage_taken(
		_amount: float, _old_health: float, 
		_new_health: float, _attacker: EntityIdentity
) -> void:
	if _is_active():
		_deactivate();

	if not health_component.is_maximum_health():
		_activate_with_delay();

	elif _is_activation_with_delay_ongoing():
		_cancel_activation_with_delay();


func _on_delay_to_activate_timer_timeout() -> void:
	_activate_after_activation_delay();


func _on_ultimate_activated() -> void:
	if _is_activation_with_delay_ongoing():
		_cancel_activation_with_delay();


func _set_active(new_active: bool) -> void:
	_active = new_active;


func _is_active() -> bool:
	return _active;


func _set_activation_with_delay_ongoing(new_activation_with_delay_ongoing: bool) -> void:
	_activation_with_delay_ongoing = new_activation_with_delay_ongoing;


func _is_activation_with_delay_ongoing() -> bool:
	return _activation_with_delay_ongoing;
