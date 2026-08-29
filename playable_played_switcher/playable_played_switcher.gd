extends Node3D


@export var playable_test_character_1: PackedScene;
@export var playable_test_character_1_identity: EntityIdentity;

@export var playable_luna_snow: PackedScene;
@export var playable_luna_snow_identity: EntityIdentity;

@export var default_playable: PackedScene;

@export var playable_spawn_marker_3d: Marker3D;

@onready var ui_panel_container: PanelContainer = %UI;
@onready var switch_prompt_screen_control: Control = %SwitchPromptScreen;
@onready var switching_to_playable_screen_control: Control = %SwitchingToPlayableScreen;

@onready var switching_to_playable_label: Label = %SwitchingToPlayableLabel;

var _playable_played: CharacterBody3D;

var _switching_playable: bool = false;


func _ready() -> void:
	ui_panel_container.hide();

	var playable: PhysicsBody3D = default_playable.instantiate();

	playable_spawn_marker_3d.add_child(playable);

	_playable_played = playable;


func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed(&"switch_playable_played"): return;
	if _switching_playable: return;

	if ui_panel_container.visible: 
		ui_panel_container.hide();
		GameState.enable_back_in_game_input();
		return;

	GameState.disable_in_game_input();

	ui_panel_container.show();


func _switch_to_playable(playable: PackedScene, playable_identity: EntityIdentity) -> void:
	_switching_playable = true;
	
	switch_prompt_screen_control.hide();
	switching_to_playable_label.text = 'Switching to Playable entity "%s"...' % playable_identity.name;
	switching_to_playable_screen_control.show();

	var new_playable_played_global_position: Vector3 = _playable_played.global_position;
	new_playable_played_global_position.y += 5.0;

	_playable_played.queue_free();

	_playable_played = playable.instantiate();
	playable_spawn_marker_3d.add_child(_playable_played);
	_playable_played.global_position = new_playable_played_global_position;

	await get_tree().create_timer(0.5).timeout;

	ui_panel_container.hide();
	switch_prompt_screen_control.visible = true;
	switching_to_playable_screen_control.visible = false;

	GameState.enable_back_in_game_input();

	_switching_playable = false;


func _on_switch_to_test_character_1_button_pressed() -> void:
	_switch_to_playable(playable_test_character_1, playable_test_character_1_identity);


func _on_switch_to_luna_snow_button_pressed() -> void:
	_switch_to_playable(playable_luna_snow, playable_luna_snow_identity);
