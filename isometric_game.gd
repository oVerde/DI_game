extends Node2D

# Configurações Isométricas
const TILE_WIDTH = 64
const TILE_HEIGHT = 32
const PLAYER_SIZE = 0.5 # Tamanho do player na grade (0.5 = metade de um bloco)

# Player
var player_grid_pos: Vector2 = Vector2(0, 0)
var speed: float = 200.0
var is_moving: bool = true

# Câmera e Transição
var camera: Camera2D
var transition_rect: ColorRect
var current_map_index: int = 0

# Dados dos Mapas
var maps = [
	{
		"name": "Entrada da Masmorra",
		"size": Vector2(10, 10),
		"spawn": Vector2(1, 1),
		"exit": Vector2(8, 8),
		"walls": [
			Vector2(3, 3), Vector2(3, 4), Vector2(3, 5),
			Vector2(6, 2), Vector2(6, 3), Vector2(7, 3)
		]
	},
	{
		"name": "Salão Principal",
		"size": Vector2(15, 15),
		"spawn": Vector2(1, 1),
		"exit": Vector2(13, 13),
		"walls": [
			Vector2(5, 5), Vector2(5, 6), Vector2(5, 7), Vector2(5, 8),
			Vector2(8, 5), Vector2(8, 6), Vector2(8, 7), Vector2(8, 8),
			Vector2(2, 10), Vector2(3, 10), Vector2(4, 10)
		]
	}
]

func _ready() -> void:
	# Configura a câmera
	camera = Camera2D.new()
	camera.zoom = Vector2(1.5, 1.5)
	add_child(camera)
	
	# Configura Transição (Fade)
	var canvas = CanvasLayer.new()
	add_child(canvas)
	transition_rect = ColorRect.new()
	transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_rect.color = Color(0, 0, 0, 0) # Transparente
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(transition_rect)
	
	# Carrega o primeiro mapa
	_load_map(0)

func _load_map(index: int) -> void:
	current_map_index = index
	var map = maps[current_map_index]
	player_grid_pos = map.spawn
	print("Entrando em: ", map.name)

func _process(delta: float) -> void:
	if is_moving:
		_handle_input(delta)
	
	queue_redraw()
	
	# Câmera segue o player
	var screen_pos = cartesian_to_isometric(player_grid_pos)
	camera.position = camera.position.lerp(screen_pos, 5.0 * delta)

func _handle_input(delta: float) -> void:
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up"): input_dir.y -= 1
	if Input.is_action_pressed("ui_down"): input_dir.y += 1
	if Input.is_action_pressed("ui_left"): input_dir.x -= 1
	if Input.is_action_pressed("ui_right"): input_dir.x += 1
	
	if input_dir == Vector2.ZERO: return
	
	input_dir = input_dir.normalized()
	
	# Converte Input Tela -> Grade
	var move_vector = Vector2.ZERO
	move_vector.x = input_dir.x + input_dir.y
	move_vector.y = input_dir.y - input_dir.x
	
	# Calcula o passo de movimento
	var move_step = move_vector * (speed / TILE_HEIGHT) * delta
	var next_pos = player_grid_pos + move_step
	
	# Tenta mover (com deslize nas paredes)
	if _is_valid_position(next_pos):
		player_grid_pos = next_pos
	else:
		# Tenta deslizar no eixo X
		var next_pos_x = player_grid_pos + Vector2(move_step.x, 0)
		if _is_valid_position(next_pos_x):
			player_grid_pos = next_pos_x
		else:
			# Tenta deslizar no eixo Y
			var next_pos_y = player_grid_pos + Vector2(0, move_step.y)
			if _is_valid_position(next_pos_y):
				player_grid_pos = next_pos_y
	
	_check_exit()

func _is_valid_position(pos: Vector2) -> bool:
	var map = maps[current_map_index]
	var size = map.size
	var half_size = PLAYER_SIZE / 2.0
	
	# 1. Limites do Mapa (Bounding Box do Player)
	if pos.x - half_size < 0 or pos.x + half_size >= size.x or \
	   pos.y - half_size < 0 or pos.y + half_size >= size.y:
		return false
	
	# 2. Paredes (Colisão AABB)
	var player_rect = Rect2(pos.x - half_size, pos.y - half_size, PLAYER_SIZE, PLAYER_SIZE)
	
	# Otimização: Checa apenas paredes vizinhas
	var start_x = floor(pos.x - 1)
	var end_x = ceil(pos.x + 1)
	var start_y = floor(pos.y - 1)
	var end_y = ceil(pos.y + 1)
	
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var wall_pos = Vector2(x, y)
			if wall_pos in map.walls:
				# Parede é um quadrado 1x1 centrado em (x, y)
				# Rect vai de x-0.5 a x+0.5
				var wall_rect = Rect2(wall_pos.x - 0.5, wall_pos.y - 0.5, 1.0, 1.0)
				
				if player_rect.intersects(wall_rect):
					return false
		
	return true

func _check_exit() -> void:
	var map = maps[current_map_index]
	# Distância simples para checar se chegou na saída
	if player_grid_pos.distance_to(map.exit) < 0.5:
		_change_level()

func _change_level() -> void:
	is_moving = false
	
	# Animação de Fade Out
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		# Troca o mapa
		var next_index = (current_map_index + 1) % maps.size()
		_load_map(next_index)
		
		# Animação de Fade In
		var tween_in = create_tween()
		tween_in.tween_property(transition_rect, "color:a", 0.0, 0.5)
		tween_in.tween_callback(func(): is_moving = true)
	)

func _draw() -> void:
	var map = maps[current_map_index]
	var size_x = int(map.size.x)
	var size_y = int(map.size.y)
	
	# Lista de objetos para desenhar (Paredes + Player)
	# Cada item: { "pos": Vector2, "type": "wall"|"player", "depth": float }
	var draw_list = []
	
	# 1. Adiciona Paredes à lista
	for wall_pos in map.walls:
		draw_list.append({
			"pos": wall_pos,
			"type": "wall",
			"depth": wall_pos.x + wall_pos.y
		})
	
	# 2. Adiciona Player à lista
	draw_list.append({
		"pos": player_grid_pos,
		"type": "player",
		"depth": player_grid_pos.x + player_grid_pos.y
	})
	
	# 3. Ordena por profundidade (Painter's Algorithm)
	draw_list.sort_custom(func(a, b): return a.depth < b.depth)
	
	# --- DESENHO ---
	
	# A. Desenha o Chão (Sempre atrás)
	for x in range(size_x):
		for y in range(size_y):
			var tile_pos = cartesian_to_isometric(Vector2(x, y))
			var color = Color(0.3, 0.3, 0.3)
			
			# Destaca a saída
			if Vector2(x, y) == map.exit:
				color = Color(0.2, 0.8, 0.2) # Verde
			
			_draw_iso_tile(tile_pos, color)
	
	# B. Desenha Objetos Ordenados (Paredes e Player)
	for item in draw_list:
		var screen_pos = cartesian_to_isometric(item.pos)
		if item.type == "wall":
			_draw_iso_cube(screen_pos, Color(0.5, 0.4, 0.3), 60) # Parede Marrom
		elif item.type == "player":
			_draw_iso_cube(screen_pos, Color.CYAN, 40) # Player Azul

# Converte coordenadas da Grade (Cartesiana) para Tela (Isométrica)
func cartesian_to_isometric(cart: Vector2) -> Vector2:
	var screen = Vector2()
	screen.x = (cart.x - cart.y) * (TILE_WIDTH / 2.0)
	screen.y = (cart.x + cart.y) * (TILE_HEIGHT / 2.0)
	return screen

# Desenha um losango (tile plano)
func _draw_iso_tile(pos: Vector2, color: Color) -> void:
	var points = PackedVector2Array([
		pos + Vector2(0, -TILE_HEIGHT / 2.0),
		pos + Vector2(TILE_WIDTH / 2.0, 0),
		pos + Vector2(0, TILE_HEIGHT / 2.0),
		pos + Vector2(-TILE_WIDTH / 2.0, 0)
	])
	draw_polygon(points, PackedColorArray([color]))
	draw_polyline(points, Color.BLACK, 1.0)

# Desenha um cubo isométrico
func _draw_iso_cube(pos: Vector2, color: Color, height: int) -> void:
	var base_pos = pos + Vector2(0, 0) # Base no chão
	
	# Face Superior (Topo)
	var top_points = PackedVector2Array([
		base_pos + Vector2(0, -TILE_HEIGHT / 2.0 - height),
		base_pos + Vector2(TILE_WIDTH / 2.0, -height),
		base_pos + Vector2(0, TILE_HEIGHT / 2.0 - height),
		base_pos + Vector2(-TILE_WIDTH / 2.0, -height)
	])
	draw_polygon(top_points, PackedColorArray([color.lightened(0.2)]))
	draw_polyline(top_points, Color.BLACK, 1.0)
	
	# Face Direita
	var right_points = PackedVector2Array([
		base_pos + Vector2(0, TILE_HEIGHT / 2.0 - height),
		base_pos + Vector2(TILE_WIDTH / 2.0, -height),
		base_pos + Vector2(TILE_WIDTH / 2.0, 0),
		base_pos + Vector2(0, TILE_HEIGHT / 2.0)
	])
	draw_polygon(right_points, PackedColorArray([color.darkened(0.2)]))
	draw_polyline(right_points, Color.BLACK, 1.0)
	
	# Face Esquerda
	var left_points = PackedVector2Array([
		base_pos + Vector2(0, TILE_HEIGHT / 2.0 - height),
		base_pos + Vector2(-TILE_WIDTH / 2.0, -height),
		base_pos + Vector2(-TILE_WIDTH / 2.0, 0),
		base_pos + Vector2(0, TILE_HEIGHT / 2.0)
	])
	draw_polygon(left_points, PackedColorArray([color.darkened(0.4)]))
	draw_polyline(left_points, Color.BLACK, 1.0)
