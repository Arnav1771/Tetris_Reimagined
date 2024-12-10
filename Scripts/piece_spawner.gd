# piece_spawner.gd

extends Node

var current_tetromino
var next_tetromino 

@onready var board = $"../Board" as Board
@onready var ui = $"../UI" as UI
var is_game_over = false

func _ready():
	current_tetromino = Shared.Tetromino.values().pick_random()	
	next_tetromino = Shared.Tetromino.values().pick_random()	
	board.spawn_tetromino(current_tetromino, false, null)
	board.spawn_tetromino(next_tetromino, true, Vector2(100, 50))
	board.tetromino_locked.connect(on_tetromino_locked)
	ui.connect("tetromino_selected", Callable(self, "_on_tetromino_selected"))
	#board.game_over.connect(on_game_over)
	
func on_tetromino_locked():
	if is_game_over:
		return
	current_tetromino = next_tetromino
	next_tetromino = Shared.Tetromino.values().pick_random()
	board.spawn_tetromino(current_tetromino, false, null)
	board.spawn_tetromino(next_tetromino, true, Vector2(100, 50))

func _on_tetromino_selected(position: Vector2):
	board.place_tetromino(current_tetromino, position)
	current_tetromino = next_tetromino
	next_tetromino = Shared.Tetromino.values().pick_random()
	board.spawn_tetromino(next_tetromino, true, Vector2(100, 50))
