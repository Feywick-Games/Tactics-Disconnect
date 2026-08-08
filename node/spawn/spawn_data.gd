class_name SpawnData
extends Resource

enum Trigger
{
	TURN_NUMBER,
	ENEMIES_REMAINING,
	SPECIAL
}

@export
var trigger: SpawnData.Trigger
@export
var value: int
@export
var character_scene: PackedScene
@export
var facing: Vector2i = Vector2i.DOWN

var spawn_global_position: Vector2
