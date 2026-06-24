class_name SfxPlayer
extends AudioStreamPlayer2D

func play_sfx(pitch_shift := true) -> void:
	pitch_scale = 1 + randf_range(0.05,0.05)
	play()
