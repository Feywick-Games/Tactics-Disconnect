class_name GamePadIndicator
extends TextureRect

var texture_dict: Dictionary[String,AtlasTexture] = {
	"accept" : load("res://ui/_sprite/push_button_a_atlas.atlastex")
	, "cancel" : load("res://ui/_sprite/push_button_b.atlastex")
	, "move_down" : load("res://ui/_sprite/push_button_down.atlastex")
	, "move_left" : load("res://ui/_sprite/push_button_left.atlastex")
	, "move_right" : load("res://ui/_sprite/push_button_right.atlastex")
	, "move_up" : load("res://ui/_sprite/push_button_up.atlastex")
}

@onready
var animator: AnimationPlayer = $AnimationPlayer
var current_action: String

func present(action: String, pressed:=false, highlighted:=false) -> void:
	texture = texture_dict[action].duplicate()
	var atlas_tex: AtlasTexture = texture
	if pressed:
		atlas_tex.region.position.x = 80
	else:
		atlas_tex.region.position.x = 16
	if highlighted:
		atlas_tex.region.position.y = 80
	else:
		atlas_tex.region.position.y = 16
	texture = texture.duplicate_deep(Resource.DEEP_DUPLICATE_NONE)
	current_action = action
