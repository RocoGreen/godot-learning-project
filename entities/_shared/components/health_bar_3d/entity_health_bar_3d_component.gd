@tool

class_name EntityHealthBar3DComponent
extends Node3D


@export_group("Dependencies")
@export var health_component: EntityHealthComponent:
	set(new_health_component):
		health_component = new_health_component;

		if not new_health_component: return;

		if Engine.is_editor_hint():
			if is_node_ready():
				_update_progress_bar_3d();
		else:
			new_health_component.healed.connect(_on_entity_healed);
			new_health_component.damaged.connect(_on_entity_damaged);

@export_group("Settings")
@export var health_bar_background_color: Color = Color.BLACK:
	set(new_health_bar_background_color):
		health_bar_background_color = new_health_bar_background_color;

		if is_node_ready():
			_update_progress_bar_3d();

@export var health_bar_health_remaining_color: Color = Color.GREEN:
	set(new_health_bar_health_remaining_color):
		health_bar_health_remaining_color = new_health_bar_health_remaining_color;

		if is_node_ready():
			_update_progress_bar_3d();

@export var health_bar_width_size: float = 1.0:
	set(new_health_bar_width_size):
		health_bar_width_size = new_health_bar_width_size;

		if is_node_ready():
			_update_progress_bar_3d();

@export var health_bar_height_size: float = 0.1:
	set(new_health_bar_height_size):
		health_bar_height_size = new_health_bar_height_size;

		if is_node_ready():
			_update_progress_bar_3d();

@export_group("Editor Only Settings")
## [b]WARNING[/b]: Only have effect in the editor.
@export var override_current_and_maximum_health: bool = false:
	set(new_override_current_and_maximum_health):
		override_current_and_maximum_health = new_override_current_and_maximum_health;

		if is_node_ready():
			_update_progress_bar_3d();

## [b]WARNING[/b]: Only have effect in the editor.
@export var overriden_current_health: float = 50.0:
	set(new_overriden_current_health):
		new_overriden_current_health = maxf(0.0, new_overriden_current_health);

		if new_overriden_current_health > overriden_maximum_health:
			overriden_maximum_health = new_overriden_current_health;

		overriden_current_health = new_overriden_current_health;

		if is_node_ready():
			_update_progress_bar_3d();

## [b]WARNING[/b]: Only have effect in the editor.
@export var overriden_maximum_health: float = 100.0:
	set(new_overriden_maximum_health):
		new_overriden_maximum_health = maxf(0.0, new_overriden_maximum_health);

		if new_overriden_maximum_health < overriden_current_health:
			overriden_current_health = new_overriden_maximum_health;

		overriden_maximum_health = new_overriden_maximum_health;

		if is_node_ready():
			_update_progress_bar_3d();

@export_group("Editor Actions")

## [b]WARNING[/b]: This variable exists so the 
## [member EntityHealthBar3DComponent.progress_bar_3d] can be updated in the
## editor. 
## It is NOT intended to be used in other places like code so please do NOT.
@export_tool_button("Update Health Bar 3D")
var update_progress_bar_3d_action: Callable = _update_progress_bar_3d;

@onready var progress_bar_3d: ProgressBar3D = %ProgressBar3D;


func _ready() -> void:
	_update_progress_bar_3d();


func _update_progress_bar_3d() -> void:
	progress_bar_3d.size = Vector2(health_bar_width_size, health_bar_height_size);

	progress_bar_3d.background_color = health_bar_background_color;
	progress_bar_3d.progress_color = health_bar_health_remaining_color;

	# WARNING: The override only have effect in editor.
	if override_current_and_maximum_health and Engine.is_editor_hint():
		progress_bar_3d.max_value = overriden_maximum_health;
		progress_bar_3d.value = overriden_current_health;

	elif health_component:
		progress_bar_3d.max_value = health_component.max_health;
		progress_bar_3d.value = health_component.current_health;


func _on_entity_healed(
		_amount: float, _old_health: float, 
		_new_health: float, _healer: EntityIdentity,
) -> void:
	_update_progress_bar_3d();


func _on_entity_damaged(
		_amount: float, _old_health: float, 
		_new_health: float, _attacker: EntityIdentity,
) -> void:
	_update_progress_bar_3d();
