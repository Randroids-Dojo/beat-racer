extends Node2D

func _ready():
	prepare_game()

func prepare_game():
	%Camera2D.position = Vector2(0, 0)
	%Camera2D.make_current()