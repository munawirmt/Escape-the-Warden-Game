extends Node2D

const GRID_SIZE = 64
var grid_width = 11
var grid_height = 20

var astar = AStarGrid2D.new()

@onready var player = $Player
@onready var warden = $AI_Warden
@onready var exit_door = $Exit
@onready var path_line = $AI_Path_Line
@onready var walls_container = $Walls
@onready var ai_status_label = $UI/AI_Status_Label
@onready var game_over_label = $UI/Game_Over_Label

@onready var move_sound = $MoveSound
@onready var win_sound = $WinSound
@onready var lose_sound = $LoseSound

var current_level = 1
var is_game_paused = false
var active_walls = []


var levels_data = {
	1: {
		"player": Vector2i(1, 2),
		"warden": Vector2i(8, 16),
		"exit": Vector2i(9, 2),
		"walls": [
			Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3), Vector2i(3, 4),
			Vector2i(7, 2), Vector2i(7, 3), Vector2i(7, 4), Vector2i(6, 4),
			Vector2i(2, 8), Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8),
			Vector2i(6, 12), Vector2i(7, 12), Vector2i(8, 12), Vector2i(9, 12)
		]
	},
	2: {
		"player": Vector2i(1, 18),
		"warden": Vector2i(5, 9),
		"exit": Vector2i(9, 1),
		"walls": [
			Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3),
			Vector2i(4, 7), Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7),
			Vector2i(1, 11), Vector2i(2, 11), Vector2i(3, 11), Vector2i(4, 11), Vector2i(5, 11),
			Vector2i(5, 15), Vector2i(6, 15), Vector2i(7, 15), Vector2i(8, 15), Vector2i(9, 15)
		]
	},
	3: {
		"player": Vector2i(5, 18),
		"warden": Vector2i(5, 2),
		"exit": Vector2i(5, 0),
		"walls": [
			Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3), Vector2i(7, 1), Vector2i(7, 2), Vector2i(7, 3),
			Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6),
			Vector2i(1, 10), Vector2i(2, 10), Vector2i(4, 10), Vector2i(5, 10), Vector2i(6, 10), Vector2i(8, 10), Vector2i(9, 10),
			Vector2i(3, 14), Vector2i(4, 14), Vector2i(5, 14), Vector2i(6, 14), Vector2i(7, 14)
		]
	},
	4: {
		"player": Vector2i(0, 19),
		"warden": Vector2i(10, 19),
		"exit": Vector2i(10, 0),
		"walls": [
			Vector2i(2, 18), Vector2i(2, 17), Vector2i(2, 16), Vector2i(2, 15), Vector2i(2, 14),
			Vector2i(5, 19), Vector2i(5, 18), Vector2i(5, 17), Vector2i(5, 16),
			Vector2i(8, 15), Vector2i(8, 14), Vector2i(8, 13), Vector2i(8, 12), Vector2i(8, 11),
			Vector2i(1, 9), Vector2i(2, 9), Vector2i(3, 9), Vector2i(4, 9), Vector2i(5, 9),
			Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 5)
		]
	},
	5: {
		"player": Vector2i(1, 1),
		"warden": Vector2i(9, 1),
		"exit": Vector2i(5, 18),
		"walls": [
			Vector2i(5, 0), Vector2i(5, 1), Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4),
			Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6),
			Vector2i(3, 9), Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9), Vector2i(7, 9),
			Vector2i(1, 12), Vector2i(2, 12), Vector2i(8, 12), Vector2i(9, 12),
			Vector2i(3, 15), Vector2i(4, 15), Vector2i(6, 15), Vector2i(7, 15)
		]
	}
}


var player_grid_pos = Vector2i.ZERO
var warden_grid_pos = Vector2i.ZERO
var exit_grid_pos = Vector2i.ZERO
var swipe_start = Vector2.ZERO

func _ready():
	setup_visuals()
	load_level(current_level)

func _draw():
	draw_rect(Rect2(0, 0, grid_width * GRID_SIZE, grid_height * GRID_SIZE), Color(0.06, 0.08, 0.12))
	for x in range(grid_width + 1):
		draw_line(Vector2(x * GRID_SIZE, 0), Vector2(x * GRID_SIZE, grid_height * GRID_SIZE), Color(0.12, 0.16, 0.24), 1.5)
	for y in range(grid_height + 1):
		draw_line(Vector2(0, y * GRID_SIZE), Vector2(grid_width * GRID_SIZE, y * GRID_SIZE), Color(0.12, 0.16, 0.24), 1.5)
		
	for wall_pos in active_walls:
		var base_rect = Rect2(wall_pos.x * GRID_SIZE + 2, wall_pos.y * GRID_SIZE + 2, GRID_SIZE - 4, GRID_SIZE - 4)
		draw_rect(base_rect, Color(0.22, 0.28, 0.38))
		var top_rect = Rect2(wall_pos.x * GRID_SIZE + 8, wall_pos.y * GRID_SIZE + 8, GRID_SIZE - 16, GRID_SIZE - 16)
		draw_rect(top_rect, Color(0.35, 0.45, 0.58))


func setup_visuals():
	# പഴയ ചതുരങ്ങളെ സുതാര്യമാക്കി ഉള്ളിൽ ഗ്രാഫിക്സ് ചേർക്കുന്നു
	player.color = Color(0, 0, 0, 0)
	var p_outer = ColorRect.new()
	p_outer.size = Vector2(52, 52)
	p_outer.position = Vector2(6, 6)
	p_outer.color = Color(0.1, 0.9, 0.5) # നിയോൺ പച്ച
	var p_inner = ColorRect.new()
	p_inner.size = Vector2(24, 24)
	p_inner.position = Vector2(20, 20)
	p_inner.color = Color(0.8, 1.0, 0.9)
	player.add_child(p_outer)
	player.add_child(p_inner)

	warden.color = Color(0, 0, 0, 0)
	var w_outer = ColorRect.new()
	w_outer.size = Vector2(56, 56)
	w_outer.position = Vector2(4, 4)
	w_outer.color = Color(0.9, 0.15, 0.2) # ചുവന്ന AI റോബോട്ട്
	var w_eye = ColorRect.new()
	w_eye.size = Vector2(40, 12)
	w_eye.position = Vector2(12, 20)
	w_eye.color = Color(1.0, 0.9, 0.2) # മഞ്ഞ ലേസർ കണ്ണ്
	warden.add_child(w_outer)
	warden.add_child(w_eye)

	exit_door.color = Color(0, 0, 0, 0)
	var e_outer = ColorRect.new()
	e_outer.size = Vector2(56, 56)
	e_outer.position = Vector2(4, 4)
	e_outer.color = Color(1.0, 0.75, 0.1) # ഗോൾഡൻ പോർട്ടൽ
	var e_inner = ColorRect.new()
	e_inner.size = Vector2(32, 32)
	e_inner.position = Vector2(16, 16)
	e_inner.color = Color(0.1, 0.1, 0.15)
	exit_door.add_child(e_outer)
	exit_door.add_child(e_inner)

func play_tone(player_node: AudioStreamPlayer, freq: float, duration: float):
	# പുറത്തുനിന്ന് ഫയൽ ഇല്ലാതെ ശബ്ദം ഉണ്ടാക്കുന്ന സിന്തസൈസർ
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = duration
	player_node.stream = gen
	player_node.play()
	var playback = player_node.get_stream_playback()
	var frames = int(gen.mix_rate * duration)
	for i in range(frames):
		var t = float(i) / gen.mix_rate
		var sample = sin(TAU * freq * t) * (1.0 - (float(i) / frames)) * 0.3
		playback.push_frame(Vector2(sample, sample))

func load_level(level_num: int):
	is_game_paused = false
	game_over_label.text = ""
	active_walls.clear()
		
	astar.region = Rect2i(0, 0, grid_width, grid_height)
	astar.cell_size = Vector2(GRID_SIZE, GRID_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	if levels_data.has(level_num):
		var data = levels_data[level_num]
		player_grid_pos = data["player"]
		warden_grid_pos = data["warden"]
		exit_grid_pos = data["exit"]
		active_walls = data["walls"].duplicate()
		for wall_pos in active_walls:
			astar.set_point_solid(wall_pos, true)
	else:
		player_grid_pos = Vector2i(1, 18)
		warden_grid_pos = Vector2i(9, 10)
		exit_grid_pos = Vector2i(9, 1)
		for i in range(35):
			var rx = randi_range(0, grid_width - 1)
			var ry = randi_range(0, grid_height - 1)
			var r_pos = Vector2i(rx, ry)
			if r_pos != player_grid_pos and r_pos != warden_grid_pos and r_pos != exit_grid_pos and not active_walls.has(r_pos):
				astar.set_point_solid(r_pos, true)
				if astar.get_id_path(player_grid_pos, exit_grid_pos).is_empty() or astar.get_id_path(warden_grid_pos, player_grid_pos).is_empty():
					astar.set_point_solid(r_pos, false)
				else:
					active_walls.append(r_pos)
					
	queue_redraw()
	update_positions()
	calculate_ai_path()



func _input(event):
	if is_game_paused:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP or event.keycode == KEY_W:
			move_player(Vector2i(0, -1))
		elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
			move_player(Vector2i(0, 1))
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			move_player(Vector2i(-1, 0))
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			move_player(Vector2i(1, 0))
			
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
		else:
			var diff = event.position - swipe_start
			if diff.length() > 30:
				if abs(diff.x) > abs(diff.y):
					move_player(Vector2i(1, 0) if diff.x > 0 else Vector2i(-1, 0))
				else:
					move_player(Vector2i(0, 1) if diff.y > 0 else Vector2i(0, -1))

func move_player(dir: Vector2i):
	var new_pos = player_grid_pos + dir
	if new_pos.x >= 0 and new_pos.x < grid_width and new_pos.y >= 0 and new_pos.y < grid_height:
		if not astar.is_point_solid(new_pos):
			player_grid_pos = new_pos
			play_tone(move_sound, 440.0, 0.08) # നടക്കുന്ന ശബ്ദം
			update_positions()
			var game_ended = await check_game_status()
			if not game_ended:
				move_ai()

func move_ai():
	var path = astar.get_id_path(warden_grid_pos, player_grid_pos)
	if path.size() > 1:
		warden_grid_pos = path[1]
		update_positions()
		calculate_ai_path()
		await check_game_status()


func calculate_ai_path():
	path_line.clear_points()
	var path = astar.get_id_path(warden_grid_pos, player_grid_pos)
	for point in path:
		var pixel_pos = Vector2(point.x * GRID_SIZE + GRID_SIZE/2, point.y * GRID_SIZE + GRID_SIZE/2)
		path_line.add_point(pixel_pos)
		
	var steps_away = path.size() - 1
	if steps_away <= 3:
		ai_status_label.text = "LVL %d | AI: TARGET LOCKED (%d steps)" % [current_level, steps_away]
		ai_status_label.modulate = Color(1, 0.3, 0.3)
	else:
		ai_status_label.text = "LVL %d | AI: CALCULATING A* (%d steps)" % [current_level, steps_away]
		ai_status_label.modulate = Color(0.4, 1, 0.6)

func update_positions():
	player.position = Vector2(player_grid_pos.x * GRID_SIZE, player_grid_pos.y * GRID_SIZE)
	warden.position = Vector2(warden_grid_pos.x * GRID_SIZE, warden_grid_pos.y * GRID_SIZE)
	exit_door.position = Vector2(exit_grid_pos.x * GRID_SIZE, exit_grid_pos.y * GRID_SIZE)

func check_game_status() -> bool:
	if player_grid_pos == exit_grid_pos:
		is_game_paused = true
		win_sound.play()
		game_over_label.text = "ESCAPED! LEVEL UP!"
		game_over_label.modulate = Color(0.2, 1, 0.2)
		await win_sound.finished # വിൻ സൗണ്ട് മുഴുവൻ തീരുന്നത് വരെ കാത്തിരിക്കും!
		current_level += 1
		load_level(current_level)
		return true
	elif player_grid_pos == warden_grid_pos:
		is_game_paused = true
		lose_sound.play()
		game_over_label.text = "CAUGHT BY AI!"
		game_over_label.modulate = Color(1, 0.2, 0.2)
		await lose_sound.finished # അലാറം സൗണ്ട് മുഴുവൻ തീരുന്നത് വരെ കാത്തിരിക്കും!
		load_level(current_level)
		return true
	return false
