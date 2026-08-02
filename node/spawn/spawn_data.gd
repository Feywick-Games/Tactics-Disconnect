class_name SpawnData
extends Resource

enum Trigger
{
	TURN_NUMBER,
	ENEMIES_REMAINING,
	SPECIAL
}

@export
var trigger: Trigger
@export
var value: Variant
@export
var character_scene: PackedScene
@export
var facing: Vector2i

var spawn_global_position: Vector2
