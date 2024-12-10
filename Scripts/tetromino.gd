# tetromino.gd

extends Node2D

class_name Tetromino

signal lock_tetromino(tetromino: Tetromino)

var bounds = {
	"min_x": -216,
	"max_x": 216,
	"max_y": 457
}

var rotation_index = 0
var wall_kicks
var tetromino_data
var is_next_piece
var pieces = []
var other_tetrominoes_pieces = [] 

@onready var piece_scene = preload("res://Scenes/piece.tscn")

var tetromino_cells
var is_dragging = false

func _ready():
	tetromino_cells = Shared.cells[tetromino_data.tetromino_type]
	
	for cell in tetromino_cells:
		var piece = piece_scene.instantiate() as Piece
		pieces.append(piece)
		add_child(piece)
		piece.set_texture(tetromino_data.piece_texture)
		piece.position = cell * piece.get_size()
	
	if is_next_piece == false:
		position = tetromino_data.spawn_position	
		wall_kicks = Shared.wall_kicks_i if tetromino_data.tetromino_type == Shared.Tetromino.I else Shared.wall_kicks_jlostz
	else: 
		set_process_input(false)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
			else:
				is_dragging = false
				align_to_grid()
				if not is_overlapping() and is_within_board():
					lock()
	elif event is InputEventMouseMotion and is_dragging:
		global_position += event.relative
	elif event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_E:
				rotate_tetromino(1)
			elif event.scancode == KEY_Q:
				rotate_tetromino(-1)

func align_to_grid():
	var x = round(global_position.x / Board.CELL_SIZE) * Board.CELL_SIZE
	var y = round(global_position.y / Board.CELL_SIZE) * Board.CELL_SIZE
	global_position = Vector2(x, y)

func is_overlapping() -> bool:
	for piece in pieces:
		for other_piece in other_tetrominoes_pieces:
			if piece.global_position == other_piece.global_position:
				return true
	return false

func is_within_board() -> bool:
	return global_position.x >= bounds.min_x and global_position.x <= bounds.max_x and global_position.y <= bounds.max_y

func lock():
	lock_tetromino.emit(self)
	set_process_input(false)

func rotate_tetromino(direction: int):
	var original_rotation_index = rotation_index
	if tetromino_data.tetromino_type == Shared.Tetromino.O:
		return
	
	apply_rotation(direction)
	
	rotation_index = wrap(rotation_index + direction, 0, 4)
	
	if not test_wall_kicks(rotation_index, direction):
		rotation_index = original_rotation_index
		apply_rotation(-direction)

func test_wall_kicks(rotation_index: int, rotation_direction: int):
	var wall_kick_index = get_wall_kick_index(rotation_index, rotation_direction)
	
	for i in wall_kicks[0].size():
		var translation = wall_kicks[wall_kick_index][i]
		if move(translation):
			return true
	return false

func get_wall_kick_index(rotation_index: int, rotation_direction):
	var wall_kick_index = rotation_index * 2
	if rotation_direction < 0:
		wall_kick_index -= 1
		
	return wrap(wall_kick_index, 0 , wall_kicks.size())

func apply_rotation(direction: int):
	var rotation_matrix = Shared.clockwise_rotation_matrix if direction == 1 else Shared.counter_clockwise_rotation_matrix
	
	var tetromino_cells = Shared.cells[tetromino_data.tetromino_type]
	
	for i in tetromino_cells.size():
		var cell = tetromino_cells[i]

		var coordinates = rotation_matrix[0] * cell.x + rotation_matrix[1]* cell.y
		tetromino_cells[i] = coordinates
	
	for i in pieces.size():
		var piece = pieces[i]
		piece.position = tetromino_cells[i] * piece.get_size()

func move(translation: Vector2) -> bool:
	var new_position = global_position + translation * Board.CELL_SIZE
	if is_within_game_bounds(translation, global_position) and not is_colliding_with_other_tetrominos(translation, global_position):
		global_position = new_position
		return true
	return false

func is_within_game_bounds(direction: Vector2, starting_global_position: Vector2):
	for piece in pieces:
		var new_position = piece.position + starting_global_position + direction * piece.get_size()
		if new_position.x < bounds.get("min_x") or new_position.x > bounds.get("max_x") or new_position.y >= bounds.get("max_y"):
			return false
	return true

func is_colliding_with_other_tetrominos(direction: Vector2, starting_global_position: Vector2):
	for tetromino_piece in other_tetrominoes_pieces:
		for piece in pieces:
			if starting_global_position + piece.position + direction * piece.get_size() == tetromino_piece.global_position:
				return true
	return false
