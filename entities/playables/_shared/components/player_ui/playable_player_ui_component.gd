class_name PlayablePlayerUIComponent
extends MarginContainer


@export var health_component: EntityHealthComponent;

@onready var health_label: Label = %HealthLabel;
@onready var health_progress_bar: ProgressBar = %HealthProgressBar;


func _ready() -> void:
	_update_playable_health_indicator();

	health_component.health_changed.connect(_on_playable_health_changed);


func _update_playable_health_indicator() -> void:
	var current_health_rounded: float = roundf(health_component.current_health);
	var max_health_rounded: float = roundf(health_component.max_health);

	health_label.text = "%s/%s" % [current_health_rounded, max_health_rounded];

	health_progress_bar.max_value = max_health_rounded;
	health_progress_bar.value = current_health_rounded;


func _on_playable_health_changed(_old_health: float, _new_health: float, _source: EntityIdentity) -> void:
	_update_playable_health_indicator();
