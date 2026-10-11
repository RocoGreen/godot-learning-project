class_name PlayablePlayerUIComponent
extends MarginContainer


@export_group("Dependencies")
@export var health_component: EntityHealthComponent;

@onready var health_label: Label = %HealthLabel;
@onready var health_progress_bar: ProgressBar = %HealthProgressBar;


func _ready() -> void:
	_update_health_label_and_progress_bar();

	health_component.health_changed.connect(_on_playable_health_changed);


func _update_health_label_and_progress_bar() -> void:
	var current_health_rounded_int: int = roundi(health_component.current_health);
	var max_health_rounded_rounded_int: int = roundi(health_component.max_health);

	health_label.text = "%s/%s" % [current_health_rounded_int, max_health_rounded_rounded_int];

	health_progress_bar.max_value = max_health_rounded_rounded_int;
	health_progress_bar.value = current_health_rounded_int;


func _on_playable_health_changed(
		_old_health: float, 
		_new_health: float, 
		_source: EntityIdentity,
) -> void:
	_update_health_label_and_progress_bar();
