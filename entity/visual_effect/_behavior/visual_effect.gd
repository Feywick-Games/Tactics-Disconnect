class_name VisualEffect
extends Node2D

const OFFSET := Vector2(0, 15)

@onready
var _sprite: Sprite2D = $Sprite2D
@onready
var _animator: AnimationPlayer = $Sprite2D/AnimationPlayer
var _detonated := false
var _direction: Vector2i
var _aoe: Array[Vector2i]
var _target_tiles : Array[Vector2i]
var _targets_only := false
var _target_tile : Vector2

func _ready() -> void:
	_sprite.hide()


func _process(_delta: float) -> void:
	if not _animator.is_playing() and _detonated:
		queue_free()


func setup(direction: Vector2i, target_tile: Vector2i, aoe: Array[Vector2i], targets: Array[Character], targets_only : bool, hit_signal: Signal) -> void:
	for target: Character in targets:
		_target_tiles.append(target.current_tile)
	_target_tile = target_tile
	_targets_only = targets_only
	hit_signal.connect(_detonate)
	global_position = GameState.current_level.tile_to_world(target_tile) - OFFSET
	_direction = direction
	_aoe = aoe


func _detonate() -> void:
	_detonated = true
	var anim: String
	
	if _direction == Vector2i.RIGHT:
		anim = "right"
	elif _direction == Vector2i.LEFT:
		anim = "left"
	elif _direction == Vector2i.UP:
		anim = "up"
	else:
		anim = "down"
	
	for tile in _aoe:
		var tile_rotated := Vector2(tile).rotated(Vector2(_direction).angle())
		if _targets_only and not tile_rotated + _target_tile in _target_tiles:
			continue
		var tile_position := tile_rotated * GameState.current_level.tile_to_world(Vector2i.ONE)
		var o_sprite: Sprite2D = _sprite.duplicate()
		add_child(o_sprite)
		o_sprite.position = tile_position
		o_sprite.show()
		_animator = o_sprite.get_node("AnimationPlayer")
		_animator.play(anim)
