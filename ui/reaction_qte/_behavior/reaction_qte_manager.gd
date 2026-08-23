class_name ReactionQteManager
extends Control

const TIME_STEP: float = .001

var success_count: int

var _reaction_qte_scene: PackedScene = load("res://ui/reaction_qte/_packed_scene/reaction_qte.tscn")
var _qtes: Array[ReactionQte]


func _ready() -> void:
	for child: Node in get_children():
		child.free()


func dispatch_qtes(screen_position: Vector2, spawn_signal: Signal, failure_signal: Signal, react_callables: Array[Callable]) -> void:
	var qte : ReactionQte = _reaction_qte_scene.instantiate()
	qte.global_position = screen_position
	qte.setup(spawn_signal, failure_signal, react_callables)
	qte.processed.connect(_remove_qte.bind(qte))
	add_child(qte)
	if _qtes.is_empty():
		qte.highlight()
	
	_qtes.append(qte)


func _remove_qte(qte: ReactionQte) -> void:
	_qtes.erase(qte)
	if not _qtes.is_empty():
		_qtes[0].highlight()


func _input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("accept") and not _qtes.is_empty() and _qtes[0].visible:
			_qtes[0].explode()
			_qtes.pop_front()
