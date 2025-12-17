extends Node2D

## Game Manager - Controlador principal do jogo
## Usa sistemas modulares: MapLoader, MapRenderer, BattleManager, IsometricUtils

# Configurações do jogador
const PLAYER_SPEED := 200.0

# Estado do jogo
enum GameState { EXPLORATION, BATTLE }
var current_state := GameState.EXPLORATION

# Referências aos sistemas
var map_renderer: MapRenderer
var battle_manager: BattleManager

# Estado do mundo
var current_map_index: int = 0
var maps: Array = []
var player_grid_pos: Vector2 = Vector2.ZERO
var nearby_interactable = null

# Estatísticas do jogador
var player_hp: int = 100
var player_max_hp: int = 100
var player_attack: int = 10

# Referências de UI/Câmera
var camera: Camera2D
var interaction_label: Label
var battle_ui_container: Control

func _ready() -> void:
	# Configurar câmera
	camera = Camera2D.new()
	camera.zoom = Vector2(1.5, 1.5)
	add_child(camera)
	
	# Configurar UI Canvas
	var canvas := CanvasLayer.new()
	add_child(canvas)
	
	# Label de interação
	interaction_label = Label.new()
	interaction_label.position = Vector2(20, 20)
	interaction_label.add_theme_font_size_override("font_size", 24)
	interaction_label.add_theme_color_override("font_color", Color.YELLOW)
	interaction_label.visible = false
	canvas.add_child(interaction_label)
	
	# Container para UI de batalha
	battle_ui_container = Control.new()
	battle_ui_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_ui_container.visible = false
	canvas.add_child(battle_ui_container)
	
	# Inicializar sistemas
	map_renderer = MapRenderer.new(self)
	battle_manager = BattleManager.new()
	add_child(battle_manager)
	battle_manager.battle_ended.connect(_on_battle_ended)
	
	# Carregar mapas
	maps = MapLoader.load_all_maps()
	
	# Gerar paredes para todos os mapas
	for map in maps:
		_generate_walls(map)
	
	# Carregar mapa inicial
	_load_map(0)

func _process(delta: float) -> void:
	match current_state:
		GameState.EXPLORATION:
			_handle_exploration(delta)
		GameState.BATTLE:
			_handle_battle(delta)

func _draw() -> void:
	if current_state == GameState.EXPLORATION:
		_draw_exploration()

## Gera paredes ao redor do mapa
func _generate_walls(map: Dictionary) -> void:
	map["walls"].clear()
	
	# Paredes horizontais
	for x in range(int(map["size"].x)):
		map["walls"].append(Vector2(x, 0))
		map["walls"].append(Vector2(x, map["size"].y - 1))
	
	# Paredes verticais
	for y in range(int(map["size"].y)):
		map["walls"].append(Vector2(0, y))
		map["walls"].append(Vector2(map["size"].x - 1, y))
	
	# Remover paredes onde há portas
	for door in map["doors"]:
		map["walls"].erase(door["pos"])

## Carrega um novo mapa
func _load_map(map_index: int) -> void:
	current_map_index = map_index
	var map := maps[current_map_index]
	player_grid_pos = map["player_spawn"]
	nearby_interactable = null
	interaction_label.visible = false
	queue_redraw()

## Lógica de exploração
func _handle_exploration(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	
	if input_vector.length() > 0:
		var move_vector := IsometricUtils.input_to_isometric_movement(input_vector)
		var new_pos := player_grid_pos + move_vector * PLAYER_SPEED * delta
		
		if _is_walkable(new_pos):
			player_grid_pos = new_pos
			queue_redraw()
	
	# Atualizar câmera
	var iso_pos := IsometricUtils.cartesian_to_isometric(player_grid_pos)
	camera.position = iso_pos
	
	# Verificar interações
	_check_interactions()
	
	# Processar input de interação
	if Input.is_action_just_pressed("interact") and nearby_interactable:
		_interact_with_nearby()

## Lógica de batalha (delegada ao BattleManager)
func _handle_battle(_delta: float) -> void:
	pass  # BattleManager cuida de tudo

## Desenha o estado de exploração
func _draw_exploration() -> void:
	var map := maps[current_map_index]
	var camera_offset := -camera.position
	
	map_renderer.set_camera_offset(camera_offset)
	
	# Desenhar chão
	map_renderer.draw_floor(map["size"])
	
	# Desenhar paredes
	map_renderer.draw_walls(map["walls"])
	
	# Desenhar entidades com depth sorting
	map_renderer.draw_scene_sorted(player_grid_pos, map["doors"], map["enemies"])
	
	# Desenhar dica de interação
	if nearby_interactable:
		var hint_pos: Vector2
		if nearby_interactable.has("pos"):
			hint_pos = nearby_interactable["pos"]
		else:
			hint_pos = nearby_interactable
		map_renderer.draw_interact_hint(hint_pos)

## Verifica se uma posição é transitável
func _is_walkable(pos: Vector2) -> bool:
	var map := maps[current_map_index]
	
	# Verificar limites
	if not IsometricUtils.is_position_valid(pos, map["size"]):
		return false
	
	# Verificar colisão com paredes
	var rounded_pos := pos.round()
	for wall in map["walls"]:
		if wall.distance_to(rounded_pos) < 0.5:
			return false
	
	return true

## Verifica objetos próximos para interação
func _check_interactions() -> void:
	var map := maps[current_map_index]
	nearby_interactable = null
	
	# Verificar portas
	for door in map["doors"]:
		if player_grid_pos.distance_to(door["pos"]) < 1.5:
			nearby_interactable = door
			interaction_label.text = "[E] Entrar"
			interaction_label.visible = true
			return
	
	# Verificar inimigos
	for enemy in map["enemies"]:
		if enemy["hp"] > 0 and player_grid_pos.distance_to(enemy["pos"]) < 1.5:
			nearby_interactable = enemy
			interaction_label.text = "[E] Batalhar"
			interaction_label.visible = true
			return
	
	interaction_label.visible = false

## Interage com objeto próximo
func _interact_with_nearby() -> void:
	if not nearby_interactable:
		return
	
	# Porta
	if nearby_interactable.has("leads_to"):
		_load_map(nearby_interactable["leads_to"])
	
	# Inimigo
	elif nearby_interactable.has("name") and nearby_interactable.has("attack"):
		_start_battle(nearby_interactable)

## Inicia uma batalha
func _start_battle(enemy: Dictionary) -> void:
	current_state = GameState.BATTLE
	interaction_label.visible = false
	battle_ui_container.visible = true
	
	var player_stats := {
		"hp": player_hp,
		"max_hp": player_max_hp,
		"attack": player_attack
	}
	
	var enemy_stats := enemy.duplicate()
	if not enemy_stats.has("max_hp"):
		enemy_stats["max_hp"] = enemy_stats["hp"]
	
	battle_manager.start_battle(player_stats, enemy_stats, battle_ui_container)

## Callback quando a batalha termina
func _on_battle_ended(victory: bool) -> void:
	battle_ui_container.visible = false
	current_state = GameState.EXPLORATION
	
	# Atualizar HP do jogador
	player_hp = battle_manager.get_player_stats()["hp"]
	
	if victory:
		# Remover inimigo do mapa
		if nearby_interactable and nearby_interactable.has("name"):
			nearby_interactable["hp"] = 0
		nearby_interactable = null
	else:
		# Jogador perdeu - resetar para mapa inicial
		if player_hp <= 0:
			player_hp = player_max_hp
			_load_map(0)
	
	queue_redraw()
