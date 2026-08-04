class_name BattleTimer
extends TextureProgressBar

signal timed_out

var running := false
var paused := false

func _ready() -> void:
	GameState.battle_timer = self
	value = 0
	max_value = Global.TIMER_MAX_VALUE
	#hide()


func stop() -> void:
	running = false
	


func start(unit: Character) -> void:
	if unit is Ally:
		show()
		
		running = true
		self.modulate = Color.WHITE
	else:
		self.modulate = Color.GRAY
	value = 0	


func _process(delta: float) -> void:
	if running:
		value += delta
		
	if value == max_value:
		timed_out.emit()
		running = false
