@tool

class_name PlayableCloakAndDagger
extends CharacterBody3D


signal switched_to_cloak;
signal switched_to_dagger;

enum PersonPlayed {
	CLOAK,
	DAGGER,
};

@export_group("Settings")
@export var default_person_played: PersonPlayed = PersonPlayed.CLOAK:
	set(new_default_person_played):
		default_person_played = new_default_person_played;

		if not Engine.is_editor_hint(): return;

		if new_default_person_played == PersonPlayed.CLOAK:
			_hide_dagger_then_show_cloak_mesh();

		elif new_default_person_played == PersonPlayed.DAGGER:
			_hide_cloak_then_show_dagger_mesh();

var _person_played: PersonPlayed;

@onready var cloak_mesh_instance_3d: MeshInstance3D = %CloakMeshInstance3D;
@onready var dagger_mesh_instance_3d: MeshInstance3D = %DaggerMeshInstance3D;


func _ready() -> void:
	_person_played = default_person_played;

	if _person_played == PersonPlayed.CLOAK:
		_hide_dagger_then_show_cloak_mesh();

	elif _person_played == PersonPlayed.DAGGER:
		_hide_cloak_then_show_dagger_mesh();


func switch_to_cloak() -> void:
	if _person_played == PersonPlayed.CLOAK: return;

	_hide_dagger_then_show_cloak_mesh();

	_person_played = PersonPlayed.CLOAK;
	switched_to_cloak.emit();


func switch_to_dagger() -> void:
	if _person_played == PersonPlayed.DAGGER: return;

	_hide_cloak_then_show_dagger_mesh();

	_person_played = PersonPlayed.DAGGER;
	switched_to_dagger.emit();


func toggle_person_played() -> void:
	if _person_played == PersonPlayed.CLOAK:
		switch_to_dagger();

	elif _person_played == PersonPlayed.DAGGER:
		switch_to_cloak();


func is_cloak_currently_played() -> bool:
	if _person_played == PersonPlayed.CLOAK:
		return true;
	else:
		return false;


func is_dagger_currently_played() -> bool:
	if _person_played == PersonPlayed.DAGGER:
		return true;
	else:
		return false;


func _hide_dagger_then_show_cloak_mesh() -> void:
	if not cloak_mesh_instance_3d or not dagger_mesh_instance_3d: return;

	if dagger_mesh_instance_3d.visible:
		dagger_mesh_instance_3d.hide();

	if not cloak_mesh_instance_3d.visible:
		cloak_mesh_instance_3d.show();


func _hide_cloak_then_show_dagger_mesh() -> void:
	if not cloak_mesh_instance_3d or not dagger_mesh_instance_3d: return;

	if cloak_mesh_instance_3d.visible:
		cloak_mesh_instance_3d.hide();

	if not dagger_mesh_instance_3d.visible:
		dagger_mesh_instance_3d.show();
