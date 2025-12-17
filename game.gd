extends Node2D

const TILE_WIDTH = 64
const TILE_HEIGHT = 32
const TILE_WIDTH_HALF = TILE_WIDTH / 2.0
const TILE_HEIGHT_HALF = TILE_HEIGHT / 2.0
const PLAYER_SIZE = 0.5
const PLAYER_HALF_SIZE = PLAYER_SIZE / 2.0
const PLAYER_HEIGHT = 40.0
const PLAYER_WIDTH = 20.0
const PLAYER_HEAD_RADIUS = 8.0
const PLAYER_SPEED = 200.0

enum GameState { EXPLORATION, BATTLE }

var current_state = GameState.EXPLORATION
var player_grid_pos: Vector2 = Vector2.ZERO
var last_camera_pos: Vector2 = Vector2.ZERO
var current_map: int = 0
var maps = [
	{
		"name": "Sala Inicial",
		"size": Vector2(15, 10),
		"player_spawn": Vector2(2, 5),
		"walls": [],
		"doors": [
			{"pos": Vector2(14, 5), "leads_to": 1, "direction": "east"}
		],
		"enemies": []
	},
	{
		"name": "Corredor",
		"size": Vector2(20, 10),
		"player_spawn": Vector2(2, 5),
		"walls": [],
		"doors": [
			{"pos": Vector2(0, 5), "leads_to": 0, "direction": "west"},
			{"pos": Vector2(19, 5), "leads_to": 2, "direction": "east"}
		],
		"enemies": []
	},
	{
		"name": "Sala do Chefe",
		"size": Vector2(15, 12),
		"player_spawn": Vector2(2, 6),
		"walls": [],
		"doors": [
			{"pos": Vector2(0, 6), "leads_to": 1, "direction": "west"}
		],
		"enemies": [
			{"pos": Vector2(10, 6), "name": "Slime", "hp": 30, "attack": 5}
		]
	}
]

var camera: Camera2D
var interaction_label: Label
var nearby_interactable = null
var battle_ui: Control
var battle_enemy = null
var player_hp: int = 100
var player_max_hp: int = 100
var player_attack: int = 10

func _ready() -> void:
	camera = Camera2D.new()
	camera.zoom = Vector2(1.5, 1.5)
	add_child(camera)
	
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	interaction_label = Label.new()
	interaction_label.position = Vector2(20, 20)
	interaction_label.add_theme_font_size_override("font_size", 24)
	interaction_label.add_theme_color_override("font_color", Color.YELLOW)
	interaction_label.visible = false
	canvas.add_child(interaction_label)
	
	battle_ui = _create_battle_ui()
	battle_ui.visible = false
	canvas.add_child(battle_ui)
	
	_load_map(0)

func _load_map(map_index: int) -> void:
	current_map = map_index
	var map = maps[current_map]
	player_grid_pos = map.player_spawn
	
	map.walls.clear()
	for x in range(int(map.size.x)):
		map.walls.append(Vector2(x, 0))
		map.walls.append(Vector2(x, map.size.y - 1))
	for y in range(int(map.size.y)):
		map.walls.append(Vector2(0, y))
		map.walls.append(Vector2(map.size.x - 1, y))
	
	for door in map.doors:
		map.walls.erase(door.pos)
	
	print("Carregado: ", map.name)
	queue_redraw()

func _process(delta: float) -> void:
	if current_state == GameState.EXPLORATION:
		_handle_exploration(delta)
		queue_redraw()
	
	var screen_pos = cartesian_to_isometric(player_grid_pos)
	var new_camera_pos = last_camera_pos.lerp(screen_pos, 5.0 * delta)
	if last_camera_pos.distance_to(new_camera_pos) > 0.1:
		camera.position = new_camera_pos
		last_camera_pos = new_camera_pos
	
	_check_interactions()

func _handle_exploration(delta: float) -> void:
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	
	if input_dir == Vector2.ZERO:
		return
	
	input_dir = input_dir.normalized()
	
	var move_vector = Vector2.ZERO
	move_vector.x = input_dir.x + input_dir.y
	move_vector.y = input_dir.y - input_dir.x
	
	var move_step = move_vector * (PLAYER_SPEED / TILE_HEIGHT) * delta
	var next_pos = player_grid_pos + move_step
	
	if _is_valid_position(next_pos):
		player_grid_pos = next_pos
	else:
		var next_pos_x = player_grid_pos + Vector2(move_step.x, 0)
		if _is_valid_position(next_pos_x):
			player_grid_pos = next_pos_x
		else:
			var next_pos_y = player_grid_pos + Vector2(0, move_step.y)
			if _is_valid_position(next_pos_y):
				player_grid_pos = next_pos_y

func _is_valid_position(pos: Vector2) -> bool:
	var map = maps[current_map]
	
	if pos.x - PLAYER_HALF_SIZE < 0 or pos.x + PLAYER_HALF_SIZE >= map.size.x or pos.y - PLAYER_HALF_SIZE < 0 or pos.y + PLAYER_HALF_SIZE >= map.size.y:
		return false
	
	var player_rect = Rect2(pos.x - PLAYER_HALF_SIZE, pos.y - PLAYER_HALF_SIZE, PLAYER_SIZE, PLAYER_SIZE)
	
	for wall in map.walls:
		var wall_rect = Rect2(wall.x - 0.5, wall.y - 0.5, 1.0, 1.0)
		if player_rect.intersects(wall_rect):
			return false
	
	return true

func _check_interactions() -> void:
	var map = maps[current_map]
	var player_grid = player_grid_pos.floor()
	nearby_interactable = null
	
	for door in map.doors:
		if player_grid.distance_to(door.pos) < 1.5:
			nearby_interactable = {"type": "door", "data": door}
			interaction_label.text = "Pressione E para passar"
			interaction_label.visible = true
			
			if Input.is_action_just_pressed("interact"):
				_enter_door(door)
			return
	
	for enemy in map.enemies:
		if player_grid.distance_to(enemy.pos) < 2.0:
			nearby_interactable = {"type": "enemy", "data": enemy}
			interaction_label.text = "Pressione E para lutar com " + enemy.name
			interaction_label.visible = true
			
			if Input.is_action_just_pressed("interact"):
				_start_battle(enemy)
			return
	
	interaction_label.visible = false

func _enter_door(door: Dictionary) -> void:
	_load_map(door.leads_to)

func _start_battle(enemy: Dictionary) -> void:
	current_state = GameState.BATTLE
	battle_enemy = enemy.duplicate()
	_update_battle_ui()
	battle_ui.visible = true
	print("Batalha iniciada contra ", enemy.name)

func _create_battle_ui() -> Control:
	var ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	
	var main_container = Control.new()
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.offset_left = -320
	main_container.offset_top = -280
	main_container.offset_right = 320
	main_container.offset_bottom = 280
	ui.add_child(main_container)
	
	var enemy_container = Control.new()
	enemy_container.position = Vector2(320, 100)
	main_container.add_child(enemy_container)
	
	var enemy_visual = ColorRect.new()
	enemy_visual.name = "EnemyVisual"
	enemy_visual.custom_minimum_size = Vector2(100, 100)
	enemy_visual.size = Vector2(100, 100)
	enemy_visual.position = Vector2(-50, -50)
	enemy_visual.color = Color(0.8, 0.2, 0.2)
	enemy_container.add_child(enemy_visual)
	
	var enemy_name = Label.new()
	enemy_name.name = "EnemyName"
	enemy_name.position = Vector2(-100, -80)
	enemy_name.custom_minimum_size = Vector2(200, 0)
	enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_name.add_theme_font_size_override("font_size", 24)
	enemy_name.add_theme_color_override("font_color", Color.WHITE)
	enemy_container.add_child(enemy_name)
	
	var dialogue_y = 220
	
	var dialogue_border = ColorRect.new()
	dialogue_border.position = Vector2(60, dialogue_y)
	dialogue_border.size = Vector2(520, 120)
	dialogue_border.color = Color.WHITE
	main_container.add_child(dialogue_border)
	
	var dialogue_bg = ColorRect.new()
	dialogue_bg.position = Vector2(68, dialogue_y + 8)
	dialogue_bg.size = Vector2(504, 104)
	dialogue_bg.color = Color.BLACK
	main_container.add_child(dialogue_bg)
	
	var dialogue_text = Label.new()
	dialogue_text.name = "DialogueText"
	dialogue_text.position = Vector2(80, dialogue_y + 15)
	dialogue_text.custom_minimum_size = Vector2(480, 80)
	dialogue_text.text = "* You got lost."
	dialogue_text.add_theme_font_size_override("font_size", 18)
	dialogue_text.add_theme_color_override("font_color", Color.WHITE)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	main_container.add_child(dialogue_text)
	
	var status_y = 360
	
	var player_name = Label.new()
	player_name.position = Vector2(60, status_y)
	player_name.text = "FRISK  LV19"
	player_name.add_theme_font_size_override("font_size", 18)
	player_name.add_theme_color_override("font_color", Color.WHITE)
	main_container.add_child(player_name)
	
	var hp_label = Label.new()
	hp_label.position = Vector2(230, status_y)
	hp_label.text = "HP"
	hp_label.add_theme_font_size_override("font_size", 18)
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	main_container.add_child(hp_label)
	
	var hp_bar_border = ColorRect.new()
	hp_bar_border.position = Vector2(270, status_y + 3)
	hp_bar_border.size = Vector2(120, 20)
	hp_bar_border.color = Color.WHITE
	main_container.add_child(hp_bar_border)
	
	var hp_bar_bg = ColorRect.new()
	hp_bar_bg.position = Vector2(272, status_y + 5)
	hp_bar_bg.size = Vector2(116, 16)
	hp_bar_bg.color = Color.BLACK
	main_container.add_child(hp_bar_bg)
	
	var hp_bar_fill = ColorRect.new()
	hp_bar_fill.name = "HPBarFill"
	hp_bar_fill.position = Vector2(272, status_y + 5)
	hp_bar_fill.size = Vector2(116, 16)
	hp_bar_fill.color = Color(1.0, 1.0, 0.0)
	main_container.add_child(hp_bar_fill)
	
	var player_hp_label = Label.new()
	player_hp_label.name = "PlayerHP"
	player_hp_label.position = Vector2(400, status_y)
	player_hp_label.add_theme_font_size_override("font_size", 18)
	player_hp_label.add_theme_color_override("font_color", Color.WHITE)
	main_container.add_child(player_hp_label)
	
	var enemy_hp = Label.new()
	enemy_hp.name = "EnemyHP"
	enemy_hp.position = Vector2(500, status_y)
	enemy_hp.add_theme_font_size_override("font_size", 16)
	enemy_hp.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	main_container.add_child(enemy_hp)
	
	var buttons_y = 420
	var button_spacing = 150
	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	
	_create_battle_button(main_container, "FIGHT", 40, buttons_y, Color(1.0, 0.0, 0.0), _on_attack_pressed, transparent_style)
	_create_battle_button(main_container, "ACT", 40 + button_spacing, buttons_y, Color(1.0, 1.0, 0.0), func(): pass, transparent_style)
	_create_battle_button(main_container, "ITEM", 40 + button_spacing * 2, buttons_y, Color(0.0, 1.0, 1.0), func(): pass, transparent_style)
	_create_battle_button(main_container, "MERCY", 40 + button_spacing * 3, buttons_y, Color(1.0, 1.0, 0.0), _on_flee_pressed, transparent_style)
	
	return ui

func _create_battle_button(container: Control, text: String, pos_x: float, pos_y: float, btn_color: Color, callback: Callable, style: StyleBoxFlat) -> void:
	var btn_container = Control.new()
	btn_container.position = Vector2(pos_x, pos_y)
	container.add_child(btn_container)
	
	var border = ColorRect.new()
	border.size = Vector2(110, 42)
	border.color = Color.WHITE
	btn_container.add_child(border)
	
	var btn_bg = ColorRect.new()
	btn_bg.position = Vector2(4, 4)
	btn_bg.size = Vector2(102, 34)
	btn_bg.color = Color.BLACK
	btn_container.add_child(btn_bg)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(110, 42)
	btn.flat = true
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.pressed.connect(callback)
	btn_container.add_child(btn)
	
	var label = Label.new()
	label.position = Vector2(10, 10)
	label.text = "* " + text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", btn_color)
	btn_container.add_child(label)

func _update_battle_ui() -> void:
	if not battle_enemy or not battle_ui:
		return
	
	var enemy_name_label = battle_ui.find_child("EnemyName", true, false)
	var enemy_hp_label = battle_ui.find_child("EnemyHP", true, false)
	var player_hp_label = battle_ui.find_child("PlayerHP", true, false)
	var hp_bar_fill = battle_ui.find_child("HPBarFill", true, false)
	
	if enemy_name_label:
		enemy_name_label.text = battle_enemy.name
	if enemy_hp_label:
		enemy_hp_label.text = "HP: " + str(max(0, battle_enemy.hp))
	if player_hp_label:
		player_hp_label.text = str(player_hp) + " / " + str(player_max_hp)
	if hp_bar_fill:
		var hp_percent = float(player_hp) / float(player_max_hp)
		hp_bar_fill.size.x = 116 * clamp(hp_percent, 0.0, 1.0)

func _on_attack_pressed() -> void:
	if not battle_enemy:
		return
	
	var dialogue_text = battle_ui.find_child("DialogueText", true, false)
	if not dialogue_text:
		return
	
	var damage = player_attack + randi() % 5
	battle_enemy.hp -= damage
	dialogue_text.text = "* You attacked " + battle_enemy.name + "!\n* " + str(damage) + " damage!"
	_update_battle_ui()
	
	await get_tree().create_timer(1.5).timeout
	
	if battle_enemy.hp <= 0:
		dialogue_text.text = "* You won!\n* Got 0 EXP and 0 GOLD."
		await get_tree().create_timer(2.0).timeout
		_end_battle(true)
		return
	
	var enemy_damage = battle_enemy.attack + randi() % 3
	player_hp -= enemy_damage
	dialogue_text.text = "* " + battle_enemy.name + " attacks!\n* You took " + str(enemy_damage) + " damage!"
	_update_battle_ui()
	
	await get_tree().create_timer(1.5).timeout
	
	if player_hp <= 0:
		dialogue_text.text = "* You lost..."
		await get_tree().create_timer(2.0).timeout
		_end_battle(false)
	else:
		dialogue_text.text = "* " + battle_enemy.name + " is preparing to attack."

func _on_flee_pressed() -> void:
	var dialogue_text = battle_ui.find_child("DialogueText", true, false)
	if dialogue_text:
		dialogue_text.text = "* You escaped!"
	await get_tree().create_timer(1.5).timeout
	_end_battle(false)

func _end_battle(victory: bool) -> void:
	battle_ui.visible = false
	current_state = GameState.EXPLORATION
	
	if victory:
		var map = maps[current_map]
		for i in range(map.enemies.size()):
			if map.enemies[i].pos == battle_enemy.pos:
				map.enemies.remove_at(i)
				break
		print("Inimigo derrotado!")
	else:
		player_hp = player_max_hp
		if player_hp <= 0:
			print("Game Over - Reiniciando...")
			_load_map(0)
	
	battle_enemy = null
	queue_redraw()

func _draw() -> void:
	if current_state == GameState.BATTLE:
		return
	
	var map = maps[current_map]
	var draw_list = []
	
	for wall in map.walls:
		draw_list.append({"pos": wall, "type": "wall", "depth": wall.x + wall.y})
	
	for door in map.doors:
		draw_list.append({"pos": door.pos, "type": "door", "depth": door.pos.x + door.pos.y})
	
	for enemy in map.enemies:
		draw_list.append({"pos": enemy.pos, "type": "enemy", "depth": enemy.pos.x + enemy.pos.y, "data": enemy})
	
	draw_list.append({"pos": player_grid_pos, "type": "player", "depth": player_grid_pos.x + player_grid_pos.y})
	draw_list.sort_custom(func(a, b): return a.depth < b.depth)
	
	for x in range(int(map.size.x)):
		for y in range(int(map.size.y)):
			var tile_pos = cartesian_to_isometric(Vector2(x, y))
			var color = Color(0.3, 0.3, 0.3)
			_draw_iso_tile(tile_pos, color)
	
	for item in draw_list:
		var screen_pos = cartesian_to_isometric(item.pos)
		
		if item.type == "wall":
			_draw_iso_tile_filled(screen_pos, Color(0.5, 0.4, 0.3))
		elif item.type == "door":
			_draw_iso_tile_filled(screen_pos, Color(0.2, 0.6, 0.2))
		elif item.type == "enemy":
			_draw_enemy(screen_pos, item.data)
		elif item.type == "player":
			_draw_player_sprite(screen_pos, Color.CYAN)

func cartesian_to_isometric(cart: Vector2) -> Vector2:
	return Vector2((cart.x - cart.y) * TILE_WIDTH_HALF, (cart.x + cart.y) * TILE_HEIGHT_HALF)

func _draw_iso_tile(pos: Vector2, color: Color) -> void:
	var points = PackedVector2Array([
		pos + Vector2(0, -TILE_HEIGHT_HALF),
		pos + Vector2(TILE_WIDTH_HALF, 0),
		pos + Vector2(0, TILE_HEIGHT_HALF),
		pos + Vector2(-TILE_WIDTH_HALF, 0)
	])
	draw_polygon(points, PackedColorArray([color]))
	draw_polyline(points, Color.BLACK, 1.0)

func _draw_iso_tile_filled(pos: Vector2, color: Color) -> void:
	var points = PackedVector2Array([
		pos + Vector2(0, -TILE_HEIGHT_HALF),
		pos + Vector2(TILE_WIDTH_HALF, 0),
		pos + Vector2(0, TILE_HEIGHT_HALF),
		pos + Vector2(-TILE_WIDTH_HALF, 0)
	])
	draw_polygon(points, PackedColorArray([color.darkened(0.2)]))

func _draw_player_sprite(pos: Vector2, color: Color) -> void:
	var head_pos = pos + Vector2(0, -(PLAYER_HEIGHT + PLAYER_HEAD_RADIUS))
	draw_circle(head_pos, PLAYER_HEAD_RADIUS, color)
	
	var body_points = PackedVector2Array([
		pos + Vector2(-PLAYER_WIDTH / 2.0, -PLAYER_HEIGHT),
		pos + Vector2(PLAYER_WIDTH / 2.0, -PLAYER_HEIGHT),
		pos + Vector2(PLAYER_WIDTH / 2.0, 0),
		pos + Vector2(-PLAYER_WIDTH / 2.0, 0)
	])
	draw_polygon(body_points, PackedColorArray([color.darkened(0.3)]))

func _draw_enemy(pos: Vector2, enemy: Dictionary) -> void:
	var enemy_pos = pos + Vector2(0, -20)
	draw_circle(enemy_pos, 15, Color.RED)
	draw_circle(enemy_pos, 15, Color.DARK_RED, false, 2.0)
	
	var font = ThemeDB.fallback_font
	var font_size = 14
	var text_pos = enemy_pos + Vector2(-20, -25)
	draw_string(font, text_pos, enemy.name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)
