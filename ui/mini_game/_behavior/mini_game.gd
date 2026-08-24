class_name MiniGame
extends Control

signal finished

enum Rank {
	UNRANKED,
	OOF,
	NORMAL,
	NICE
}

var ranking: Rank = Rank.UNRANKED:
	set(val):
		if val != Rank.UNRANKED:
			finished.emit()
		ranking = val

func is_complete() -> bool:
	return ranking != Rank.UNRANKED
