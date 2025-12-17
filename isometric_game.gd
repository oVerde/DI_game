extends Node2D

# Configurações Isométricas (Estilo Hades - Isométrica 45 graus)
const TILE_WIDTH = 64
const TILE_HEIGHT = 32  # Proporção isométrica clássica
const TILE_WIDTH_HALF = TILE_WIDTH / 2.0
const TILE_HEIGHT_HALF = TILE_HEIGHT / 2.0
const PLAYER_SIZE = 0.5 # Tamanho do player na grade (0.5 = metade de um bloco)
const PLAYER_HALF_SIZE = PLAYER_SIZE / 2.0
const PLAYER_HEIGHT = 40.0
const PLAYER_WIDTH = 20.0
const PLAYER_HEAD_RADIUS = 8.0

# Player
var player_grid_pos: Vector2 = Vector2(0, 0)
var speed: float = 200.0
var is_moving: bool = true
var last_camera_pos: Vector2 = Vector2.ZERO

# Câmera e Transição
var camera: Camera2D
var transition_rect: ColorRect
var current_map_index: int = 0

# Dados dos Mapas
var maps = [
	{
		"name": "Ilha da Masmorra",
		"size": Vector2(20, 20),
		"spawn": Vector2(10, 10),
		"exit": Vector2(15, 15),
		"walls": _generate_island_walls(Vector2(10, 10), 7.0, Vector2(20, 20))
	},
	{
		"name": "Arquipélago",
		"size": Vector2(25, 25),
		"spawn": Vector2(12, 12),
		"exit": Vector2(20, 20),
		"walls": _generate_multi_island_walls(Vector2(25, 25))
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
		# Só redesenha se houve movimento
		queue_redraw()
	
	# Câmera segue o player (com threshold para evitar updates contínuos)
	var screen_pos = cartesian_to_isometric(player_grid_pos)
	var new_camera_pos = last_camera_pos.lerp(screen_pos, 5.0 * delta)
	if last_camera_pos.distance_to(new_camera_pos) > 0.1:
		camera.position = new_camera_pos
		last_camera_pos = new_camera_pos

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
	
	# 1. Limites do Mapa (Bounding Box do Player)
	if pos.x - PLAYER_HALF_SIZE < 0 or pos.x + PLAYER_HALF_SIZE >= size.x or \
	   pos.y - PLAYER_HALF_SIZE < 0 or pos.y + PLAYER_HALF_SIZE >= size.y:
		return false
	
	# 2. Paredes (Colisão AABB) - Usa cache de walls
	var player_rect = Rect2(pos.x - PLAYER_HALF_SIZE, pos.y - PLAYER_HALF_SIZE, PLAYER_SIZE, PLAYER_SIZE)
	var walls = map.walls
	
	# Otimização: Checa apenas paredes vizinhas (reduz de O(n) para O(1) amortizado)
	var start_x = int(pos.x - 2)
	var end_x = int(pos.x + 2)
	var start_y = int(pos.y - 2)
	var end_y = int(pos.y + 2)
	
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var wall_pos = Vector2(x, y)
			if wall_pos in walls:
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
			_draw_iso_tile_filled(screen_pos, Color(0.5, 0.4, 0.3)) # Parede Marrom
		elif item.type == "player":
			_draw_player_sprite(screen_pos, Color.CYAN) # Player com altura

# Converte coordenadas da Grade (Cartesiana) para Tela (Isométrica) - Inline otimizado
func cartesian_to_isometric(cart: Vector2) -> Vector2:
	return Vector2((cart.x - cart.y) * TILE_WIDTH_HALF, (cart.x + cart.y) * TILE_HEIGHT_HALF)

# Desenha um losango (tile plano) - Estilo Hades
func _draw_iso_tile(pos: Vector2, color: Color) -> void:
	var points = PackedVector2Array([
		pos + Vector2(0, -TILE_HEIGHT_HALF),
		pos + Vector2(TILE_WIDTH_HALF, 0),
		pos + Vector2(0, TILE_HEIGHT_HALF),
		pos + Vector2(-TILE_WIDTH_HALF, 0)
	])
	draw_polygon(points, PackedColorArray([color]))
	draw_polyline(points, Color.BLACK, 1.0)

# Desenha um tile preenchido com cor escurecida - SEM polyline (mais rápido)
func _draw_iso_tile_filled(pos: Vector2, color: Color) -> void:
	var points = PackedVector2Array([
		pos + Vector2(0, -TILE_HEIGHT_HALF),
		pos + Vector2(TILE_WIDTH_HALF, 0),
		pos + Vector2(0, TILE_HEIGHT_HALF),
		pos + Vector2(-TILE_WIDTH_HALF, 0)
	])
	draw_polygon(points, PackedColorArray([color.darkened(0.2)]))

# Desenha o player - Otimizado (remove polylines desnecessárias)
func _draw_player_sprite(pos: Vector2, color: Color) -> void:
	# Cabeça (círculo no topo)
	var head_pos = pos + Vector2(0, -(PLAYER_HEIGHT + PLAYER_HEAD_RADIUS))
	draw_circle(head_pos, PLAYER_HEAD_RADIUS, color)
	
	# Corpo (retângulo vertical)
	var body_points = PackedVector2Array([
		pos + Vector2(-PLAYER_WIDTH / 2.0, -PLAYER_HEIGHT),
		pos + Vector2(PLAYER_WIDTH / 2.0, -PLAYER_HEIGHT),
		pos + Vector2(PLAYER_WIDTH / 2.0, 0),
		pos + Vector2(-PLAYER_WIDTH / 2.0, 0)
	])
	draw_polygon(body_points, PackedColorArray([color.darkened(0.1)]))
	
	# Sombra no chão (pequeno losango) - SEM polyline
	var shadow_points = PackedVector2Array([
		pos + Vector2(0, -3),
		pos + Vector2(12, 0),
		pos + Vector2(0, 3),
		pos + Vector2(-12, 0)
	])
	draw_polygon(shadow_points, PackedColorArray([Color(0, 0, 0, 0.3)]))

# ============================================
# FUNÇÕES PARA CRIAR/PERSONALIZAR MAPAS
# ============================================

# Gera paredes em formato de ilha (círculo irregular)
func _generate_island_walls(center: Vector2, base_radius: float, map_size: Vector2) -> Array:
	var walls = []
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.3
	
	# Cria o perímetro da ilha com ruído para forma natural
	for x in range(int(map_size.x)):
		for y in range(int(map_size.y)):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			
			# Adiciona ruído ao raio para criar forma irregular
			var noise_value = noise.get_noise_2d(x, y) * 1.5
			var adjusted_radius = base_radius + noise_value
			
			# Coloca parede se está fora da ilha
			if distance > adjusted_radius:
				walls.append(pos)
	
	return walls

# Gera múltiplas ilhas (arquipélago)
func _generate_multi_island_walls(map_size: Vector2) -> Array:
	var walls = []
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.25
	
	# Ilhas principais
	var islands = [
		{"center": Vector2(8, 8), "radius": 5.5},
		{"center": Vector2(18, 8), "radius": 4.5},
		{"center": Vector2(12, 16), "radius": 4.0}
	]
	
	for x in range(int(map_size.x)):
		for y in range(int(map_size.y)):
			var pos = Vector2(x, y)
			var on_island = false
			
			# Checa se está em alguma ilha
			for island in islands:
				var distance = pos.distance_to(island.center)
				var noise_value = noise.get_noise_2d(x, y) * 1.2
				var adjusted_radius = island.radius + noise_value
				
				if distance <= adjusted_radius:
					on_island = true
					break
			
			# Se não está em nenhuma ilha, é parede (água)
			if not on_island:
				walls.append(pos)
	
	return walls

# Gera um tilemap padrão (chão completo com paredes marcadas)
func _generate_tilemap(size: Vector2, wall_positions: Array) -> Dictionary:
	var tilemap = {}
	
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			var pos = Vector2(x, y)
			var tile_type = "floor"
			var tile_color = Color(0.3, 0.3, 0.3)
			
			# Se é parede, marca como tal
			if pos in wall_positions:
				tile_type = "wall"
				tile_color = Color(0.5, 0.4, 0.3)
			
			tilemap[pos] = {
				"type": tile_type,
				"color": tile_color,
				"collision": tile_type == "wall"
			}
	
	return tilemap

# Função helper para criar um retângulo de terreno
func create_rect_terrain(top_left: Vector2, width: int, height: int, _tile_type: String = "floor") -> Array:
	var tiles = []
	for x in range(width):
		for y in range(height):
			tiles.append(top_left + Vector2(x, y))
	return tiles

# Função helper para criar um círculo de terreno
func create_circle_terrain(center: Vector2, radius: float, _tile_type: String = "floor") -> Array:
	var tiles = []
	for x in range(int(center.x - radius), int(center.x + radius) + 1):
		for y in range(int(center.y - radius), int(center.y + radius) + 1):
			if Vector2(x, y).distance_to(center) <= radius:
				tiles.append(Vector2(x, y))
	return tiles