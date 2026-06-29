class_name BattleTimer
extends TextureProgressBar

var running := false

func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	GameState.battle_timer = self
	EventBus.encounter_ended.connect(_on_encounter_ended)
	value = 0
	max_value = Global.TIMER_MAX_VALUE
	EventBus.timer_stopped.connect(_on_timer_stopped)
	hide()


func _on_timer_stopped() -> void:
	running = false


func _on_encounter_ended() -> void:
	hide()


func _on_turn_started(unit: Character) -> void:
	if unit is Ally:
		show()
		
		running = true
		self.modulate = Color.WHITE
	else:
		self.modulate = Color.GRAY
	value = 0


func _on_turn_ended() -> void:
	running = false
	
	
func _process(delta: float) -> void:
	if running:
		value += delta
		
	if value == max_value:
		EventBus.timed_out.emit()
		running = false
