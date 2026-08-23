class_name MiniGame
extends Control

signal finished

var value: float
var completed: bool = false:
	set(val):
		if val == true:
			finished.emit()
		completed = val
		
var success: bool = false
