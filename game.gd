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
		"enemies": [],
		# Objetos do mapa (NPCs, itens, etc.)
		"objects": [
			{"pos": Vector2(10, 5), "type": "npc", "name": "Guard", "dialogue": "Nunca achei que fosses chegar a este ponto... Já não tens muito tempo para sair daqui. Boa sorte na tua jornada. Eu acredito em ti"}
		]
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
			{"pos": Vector2(2, 10), "name": "Espelho", "hp": 30, "attack": 5, "dialogue": "Você se aproxima do espelho... Algo sinistro reflete de volta."},
			{"pos": Vector2(10, 6), "name": "Livro", "hp": 30, "attack": 5, "dialogue": "Você encontra um livro antigo no canto da sala.", "no_battle": true},
			{"pos": Vector2(1, 1), "name": "Casaco", "hp": 25, "attack": 4, "dialogue": "Um casaco está largado no chão.", "no_battle": true}
		   ,{"pos": Vector2(4, 3), "name": "Cadeira", "hp": 20, "attack": 0, "dialogue": "Uma cadeira velha range quando você se aproxima. Parece ter visto muitas histórias.", "no_battle": true}
		   ,{"pos": Vector2(12, 8), "name": "Abajur", "hp": 20, "attack": 0, "dialogue": "O abajur pisca suavemente, iluminando memórias esquecidas.", "no_battle": true}
		   ,{"pos": Vector2(7, 2), "name": "Quadro", "hp": 20, "attack": 0, "dialogue": "O quadro na parede mostra uma paisagem serena, mas há algo inquietante em seu olhar.", "no_battle": true}
		   ,{"pos": Vector2(13, 4), "name": "Relógio", "hp": 20, "attack": 0, "dialogue": "O relógio faz tique-taque, lembrando que o tempo nunca para.", "no_battle": true}
		   ,{"pos": Vector2(5, 10), "name": "Almofada", "hp": 20, "attack": 0, "dialogue": "Uma almofada macia parece convidar para um breve descanso.", "no_battle": true}
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

var LoggerClass = preload("res://scripts/utils/logger.gd") # DJLogger
var logger = null
var last_selected_option_index: int = -1
var recently_damaged: bool = false

var dialogue_active: bool = false
var dialogue_box: Panel
var dialogue_label: Label
var pending_battle_enemy = null
var last_input_gamepad: bool = false
var continue_hint: Label = null
var current_interaction_action: String = ""

var conversation_menu_active: bool = false
var conversation_options_container: Control = null
var battle_dialogue_rounds = [
	[
		{"text": "Encarar a verdade", "player_hp": -18, "enemy_hp": -12, "result": "Você encara a verdade e o espelho se parte um pouco."},
		{"text": "Fugir da realidade", "player_hp": -28, "enemy_hp": 0, "result": "O espelho brilha e te fere por fugir da verdade."},
		{"text": "Refletir sobre si", "player_hp": -15, "enemy_hp": -9, "result": "Você reflete e ambos se enfraquecem."},
		{"text": "Aceitar o passado", "player_hp": -12, "enemy_hp": -8, "result": "Aceitar o passado dói, mas enfraquece o espelho."}
	],
	[
		{"text": "Desafiar o espelho", "player_hp": -20, "enemy_hp": -15, "result": "Você desafia o espelho, que trinca mais."},
		{"text": "Negar o reflexo", "player_hp": -25, "enemy_hp": -5, "result": "Negar o reflexo te enfraquece, mas o espelho hesita."},
		{"text": "Buscar esperança", "player_hp": -10, "enemy_hp": -10, "result": "Você busca esperança e o espelho perde força."},
		{"text": "Gritar com raiva", "player_hp": -22, "enemy_hp": -7, "result": "Sua raiva te consome, mas o espelho se abala."}
	],
	[
		{"text": "Aceitar quem você é", "player_hp": -8, "enemy_hp": -20, "result": "Você aceita quem é, o espelho quase quebra."},
		{"text": "Desistir", "player_hp": -30, "enemy_hp": 0, "result": "Você desiste e o espelho se fortalece."},
		{"text": "Pedir perdão", "player_hp": -12, "enemy_hp": -15, "result": "Você pede perdão e o espelho se parte mais."},
		{"text": "Enfrentar o medo", "player_hp": -15, "enemy_hp": -18, "result": "Você enfrenta o medo e o espelho racha."}
	]
]
var current_battle_round = 0

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
	
	# Criar UI de diálogo
	dialogue_box = Panel.new()
	dialogue_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_box.offset_left = -400
	dialogue_box.offset_right = 400
	dialogue_box.offset_top = -150
	dialogue_box.offset_bottom = -30
	dialogue_box.visible = false
	
	var dialogue_style = StyleBoxFlat.new()
	dialogue_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	dialogue_style.border_color = Color.WHITE
	dialogue_style.set_border_width_all(3)
	dialogue_style.set_corner_radius_all(10)
	dialogue_box.add_theme_stylebox_override("panel", dialogue_style)
	
	dialogue_label = Label.new()
	dialogue_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogue_label.offset_left = 20
	dialogue_label.offset_right = -20
	dialogue_label.offset_top = 20
	dialogue_label.offset_bottom = -20
	dialogue_label.add_theme_font_size_override("font_size", 20)
	dialogue_label.add_theme_color_override("font_color", Color.WHITE)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_box.add_child(dialogue_label)
	
	continue_hint = Label.new()
	continue_hint.text = "[Pressione " + _interact_hint_plain() + " para continuar]"
	continue_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	continue_hint.offset_left = -250
	continue_hint.offset_right = -20
	continue_hint.offset_top = -30
	continue_hint.offset_bottom = -10
	continue_hint.add_theme_font_size_override("font_size", 14)
	continue_hint.add_theme_color_override("font_color", Color(1, 1, 0.5, 0.8))
	dialogue_box.add_child(continue_hint) 
	
	canvas.add_child(dialogue_box)

	# Instanciar logger e iniciar sessão
	if LoggerClass:
		logger = LoggerClass.new()
		add_child(logger)
		logger.start_new_session()
	else:
		logger = null

	_load_map(0)  # Começar direto na Sala do Chefe

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
	
	# Debug: verificar objetos
	if map.has("objects"):
		print("Objetos encontrados: ", map["objects"].size())
		for obj in map["objects"]:
			print("  - ", obj.name, " em ", obj.pos)
	else:
		print("Sem objetos neste mapa")
	
	print("Carregado: ", map.name)
	queue_redraw()

	# Log sensoriality: entrada em sala
	if logger:
		logger.log_location_entered(current_map, player_grid_pos.floor())

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

func _input(event) -> void:
	# Detectar último dispositivo de entrada (joystick vs teclado/mouse)
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		last_input_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		last_input_gamepad = false
	
	# Atualizar texto do continue_hint se visível
	if continue_hint and dialogue_box and dialogue_box.visible:
		continue_hint.text = "[Pressione " + _interact_hint_plain() + " para continuar]"
	
	# Atualizar texto de interação se visível
	if interaction_label and interaction_label.visible and current_interaction_action != "":
		_update_interaction_label_text(current_interaction_action)

func _interact_hint() -> String:
	return "[A]" if last_input_gamepad else "[E]"

func _interact_hint_plain() -> String:
	return "A" if last_input_gamepad else "E"

func _update_interaction_label_text(action_text: String) -> void:
	current_interaction_action = action_text
	interaction_label.text = _interact_hint() + " " + action_text
	interaction_label.visible = true

func _handle_exploration(delta: float) -> void:
	# Bloquear movimento enquanto há diálogo ativo
	if dialogue_active:
		return
	
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
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
	# Bloquear interações durante batalha
	if current_state == GameState.BATTLE:
		interaction_label.visible = false
		return

	# Se diálogo está ativo, fecha o diálogo
	if dialogue_active:
		if Input.is_action_just_pressed("interact"):
			_close_dialogue()
		return
	
	var map = maps[current_map]
	var player_grid = player_grid_pos.floor()
	nearby_interactable = null
	
	for door in map.doors:
		if player_grid.distance_to(door.pos) < 1.5:
			nearby_interactable = {"type": "door", "data": door}
			_update_interaction_label_text("Entrar")
			
			if Input.is_action_just_pressed("interact"):
				if logger:
					logger.log_object_touched("door_" + str(door.pos), true, player_grid)
				_enter_door(door)
			return
	

	for enemy in map.enemies:
		if enemy.hp > 0 and player_grid.distance_to(enemy.pos) < 2.0:
			nearby_interactable = {"type": "enemy", "data": enemy}
			_update_interaction_label_text(enemy.name)
			
			if Input.is_action_just_pressed("interact"):
				if logger:
					logger.log_object_touched(enemy.name, true, player_grid)
				_show_dialogue(enemy)
			return
	
	# Verificar NPCs/objetos para interação
	if map.has("objects"):
		for obj in map.objects:
			if obj.type == "npc" and player_grid.distance_to(obj.pos) < 1.5:
				nearby_interactable = {"type": "npc", "data": obj}
				_update_interaction_label_text("Conversar")
				
				if Input.is_action_just_pressed("interact"):
					if logger:
						logger.log_object_touched(obj.name, false, player_grid)
					_show_npc_dialogue(obj)
				return
	
	interaction_label.visible = false

func _enter_door(door: Dictionary) -> void:
	_load_map(door.leads_to)

func _show_dialogue(enemy: Dictionary) -> void:
	# Não permitir diálogo durante batalha
	if dialogue_active or current_state == GameState.BATTLE:
		return

	dialogue_active = true
	pending_battle_enemy = enemy
	interaction_label.visible = false
	
	# Mostrar diálogo do inimigo
	var enemy_dialogue_text = enemy.get("dialogue", "...")
	dialogue_label.text = enemy_dialogue_text
	dialogue_box.visible = true

func _show_npc_dialogue(obj: Dictionary) -> void:
	# Não permitir diálogo durante batalha
	if dialogue_active or current_state == GameState.BATTLE:
		return
	
	dialogue_active = true
	interaction_label.visible = false
	
	# Mostrar diálogo do NPC (não inicia batalha)
	var dialogue_text = obj.get("dialogue", "...")
	dialogue_label.text = dialogue_text
	dialogue_box.visible = true

func _close_dialogue() -> void:
		dialogue_active = false
		dialogue_box.visible = false

		# Se havia um inimigo pendente, iniciar batalha, exceto se for só diálogo
		if pending_battle_enemy:
			if not pending_battle_enemy.has("no_battle") or not pending_battle_enemy.no_battle:
				_start_battle(pending_battle_enemy)
			pending_battle_enemy = null

func _start_battle(enemy: Dictionary) -> void:
	current_state = GameState.BATTLE
	battle_enemy = enemy.duplicate()
	_update_battle_ui()
	battle_ui.visible = true
	print("Batalha iniciada contra ", enemy.name)
	current_battle_round = 0
	_show_battle_options()

func _show_battle_options():
	if conversation_options_container:
		conversation_options_container.queue_free()
	conversation_options_container = VBoxContainer.new()
	conversation_options_container.name = "BattleOptions"
	conversation_options_container.anchor_left = 0.7
	conversation_options_container.anchor_top = 0.7
	conversation_options_container.anchor_right = 0.98
	conversation_options_container.anchor_bottom = 0.98
	var options = battle_dialogue_rounds[min(current_battle_round, battle_dialogue_rounds.size() - 1)]
	for i in range(len(options)):
		var option = options[i]
		var btn = Button.new()
		btn.text = option.text
		# captura o índice para sabermos qual opção foi escolhida
		btn.pressed.connect(func(opt_idx=i, opt_val=option): _on_battle_option_selected(opt_val, opt_idx))
		conversation_options_container.add_child(btn)

	# Log: opções exibidas
	if logger:
		logger.log_event("option_displayed", {"dialog_id": current_battle_round}, player_grid_pos.floor())
	battle_ui.add_child(conversation_options_container)

func _on_battle_option_selected(option: Dictionary, option_index: int = -1):
	# Se veio de um dano recente, isto pode ser considerado uma reação
	if recently_damaged and logger:
		logger.log_action("reaction_action", {"option_number": option_index}, player_grid_pos.floor())
		recently_damaged = false

	# Log da ação de seleção de opção
	if logger:
		var alignment_tag = "good" if option.get("enemy_hp", 0) < 0 else "bad"
		logger.log_action("option_selected", {"dialog_id": current_battle_round, "option_number": option_index, "narrative_alignment_tag": alignment_tag}, player_grid_pos.floor())

	last_selected_option_index = option_index

	# Guardar estados antigos para detectar mudanças de HP
	var old_player_hp = player_hp
	var old_enemy_hp = battle_enemy.hp

	player_hp += option.player_hp
	battle_enemy.hp += option.enemy_hp

	if player_hp > player_max_hp:
		player_hp = player_max_hp
	if battle_enemy.hp < 0:
		battle_enemy.hp = 0
	if player_hp < 0:
		player_hp = 0

	# Log de mudanças de estado (HP)
	if logger:
		if player_hp != old_player_hp:
			logger.log_state("heath_changed", {"who": "player", "old_health_value": old_player_hp, "option_number": option_index}, player_grid_pos.floor())
		if battle_enemy and battle_enemy.hp != old_enemy_hp:
			logger.log_state("heath_changed", {"who": "enemy", "old_health_value": old_enemy_hp, "option_number": option_index}, player_grid_pos.floor())

	_update_battle_ui()
	_show_battle_result(option.result)
	current_battle_round += 1

func _show_battle_result(result_text: String):
	var dialogue = battle_ui.find_child("DialogueText", true, false)
	if dialogue:
		dialogue.text = result_text
	if conversation_options_container:
		conversation_options_container.queue_free()
		conversation_options_container = null
	await get_tree().create_timer(1.5).timeout
	_check_battle_end()

func _check_battle_end():
	if player_hp <= 0:
		_reset_game()
		return
	if battle_enemy.hp <= 0:
		_end_battle(true)
		return
	_show_battle_options()

func _reset_game():
	player_hp = player_max_hp
	current_state = GameState.EXPLORATION
	battle_ui.visible = false
	_load_map(0)
	print("O jogador morreu. Jogo reiniciado.")


func _create_battle_ui() -> Control:
	var ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Fundo simples
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	
	# Container principal
	var main = Control.new()
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.offset_left = 40
	main.offset_right = -40
	main.offset_top = 40
	main.offset_bottom = -40
	ui.add_child(main)
	
	# ===== NOME DO INIMIGO (Topo) =====
	var enemy_name = Label.new()
	enemy_name.name = "EnemyName"
	enemy_name.text = "Espelho"
	enemy_name.position = Vector2(0, 10)
	enemy_name.add_theme_font_size_override("font_size", 32)
	enemy_name.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	main.add_child(enemy_name)
	
	# Linha separadora
	var line1 = ColorRect.new()
	line1.position = Vector2(0, 50)
	line1.size = Vector2(1200, 2)
	line1.color = Color(0.3, 0.5, 0.8, 0.5)
	main.add_child(line1)
	
	# ===== DIÁLOGO CENTRAL =====
	var dialogue = Label.new()
	dialogue.name = "DialogueText"
	dialogue.text = "O espelho reflete seu olhar..."
	dialogue.position = Vector2(0, 80)
	dialogue.size = Vector2(1200, 200)
	dialogue.add_theme_font_size_override("font_size", 20)
	dialogue.add_theme_color_override("font_color", Color.WHITE)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	main.add_child(dialogue)
	
	# Linha separadora
	var line2 = ColorRect.new()
	line2.position = Vector2(0, 300)
	line2.size = Vector2(1200, 2)
	line2.color = Color(0.3, 0.5, 0.8, 0.5)
	main.add_child(line2)
	
	# ===== STATUS (HP) =====
	var hp_section = Control.new()
	hp_section.position = Vector2(0, 330)
	main.add_child(hp_section)
	
	var enemy_hp_label = Label.new()
	enemy_hp_label.text = "Inimigo HP:"
	enemy_hp_label.add_theme_font_size_override("font_size", 14)
	enemy_hp_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	hp_section.add_child(enemy_hp_label)
	
	var enemy_hp_bar_bg = ColorRect.new()
	enemy_hp_bar_bg.position = Vector2(150, 4)
	enemy_hp_bar_bg.size = Vector2(300, 16)
	enemy_hp_bar_bg.color = Color(0.15, 0.15, 0.15, 1.0)
	hp_section.add_child(enemy_hp_bar_bg)
	
	var enemy_hp_bar = ColorRect.new()
	enemy_hp_bar.name = "EnemyHPBar"
	enemy_hp_bar.position = Vector2(150, 4)
	enemy_hp_bar.size = Vector2(300, 16)
	enemy_hp_bar.color = Color(1.0, 0.3, 0.3, 1.0)
	hp_section.add_child(enemy_hp_bar)
	
	var enemy_hp_text = Label.new()
	enemy_hp_text.name = "EnemyHP"
	enemy_hp_text.text = "30/30"
	enemy_hp_text.position = Vector2(460, 0)
	enemy_hp_text.add_theme_font_size_override("font_size", 14)
	enemy_hp_text.add_theme_color_override("font_color", Color.WHITE)
	hp_section.add_child(enemy_hp_text)
	
	# Player HP
	var player_hp_label = Label.new()
	player_hp_label.text = "Seu HP:"
	player_hp_label.position = Vector2(600, 0)
	player_hp_label.add_theme_font_size_override("font_size", 14)
	player_hp_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	hp_section.add_child(player_hp_label)
	
	var player_hp_bar_bg = ColorRect.new()
	player_hp_bar_bg.position = Vector2(720, 4)
	player_hp_bar_bg.size = Vector2(200, 16)
	player_hp_bar_bg.color = Color(0.15, 0.15, 0.15, 1.0)
	hp_section.add_child(player_hp_bar_bg)
	
	var player_hp_bar = ColorRect.new()
	player_hp_bar.name = "PlayerHPBar"
	player_hp_bar.position = Vector2(720, 4)
	player_hp_bar.size = Vector2(200, 16)
	player_hp_bar.color = Color(0.3, 1.0, 0.3, 1.0)
	hp_section.add_child(player_hp_bar)
	
	var player_hp_text = Label.new()
	player_hp_text.name = "PlayerHP"
	player_hp_text.text = "100/100"
	player_hp_text.position = Vector2(930, 0)
	player_hp_text.add_theme_font_size_override("font_size", 14)
	player_hp_text.add_theme_color_override("font_color", Color.WHITE)
	hp_section.add_child(player_hp_text)
	
	# ===== MENU DE AÇÕES =====
	var actions = Control.new()
	actions.position = Vector2(0, 400)
	main.add_child(actions)
	
	var btn_positions = [0, 290, 580, 870]
	var btn_colors = [Color(1.0, 0.6, 0.2, 1.0), Color(0.3, 1.0, 0.8, 1.0), Color(0.8, 0.6, 1.0, 1.0), Color(1.0, 0.8, 0.3, 1.0)]
	var btn_texts = ["Fugir"]
	var btn_callbacks = [_on_flee_pressed]
	
	for i in range(len(btn_texts)):
		var btn = Button.new()
		btn.position = Vector2(btn_positions[i], 0)
		btn.size = Vector2(270, 40)
		btn.text = btn_texts[i]
		btn.flat = true
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", btn_colors[i])
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(btn_colors[i].r * 0.2, btn_colors[i].g * 0.2, btn_colors[i].b * 0.2, 0.8)
		style.border_color = btn_colors[i]
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		
		btn.pressed.connect(btn_callbacks[i])
		actions.add_child(btn)
	
	# ===== MENU DE CONVERSA (OCULTO) =====
	conversation_options_container = Control.new()
	conversation_options_container.name = "ConversationOptions"
	conversation_options_container.visible = false
	conversation_options_container.position = Vector2(0, 300)
	main.add_child(conversation_options_container)
	
	# Background para o menu
	var conv_bg = ColorRect.new()
	conv_bg.size = Vector2(1200, 250)
	conv_bg.color = Color(0.02, 0.02, 0.05, 0.95)
	conversation_options_container.add_child(conv_bg)
	conversation_options_container.move_child(conv_bg, 0)  # Enviar para trás
	
	var conv_title = Label.new()
	conv_title.text = "O que você quer dizer?"
	conv_title.add_theme_font_size_override("font_size", 18)
	conv_title.add_theme_color_override("font_color", Color(0.7, 1.0, 1.0, 1.0))
	conversation_options_container.add_child(conv_title)
	
	for i in range(len(btn_texts)):
		var btn = Button.new()
		btn.position = Vector2(btn_positions[i], 0)
		btn.size = Vector2(270, 40)
		btn.text = btn_texts[i]
		btn.flat = true
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", btn_colors[i])
		var style = StyleBoxFlat.new()
		style.bg_color = Color(btn_colors[i].r * 0.2, btn_colors[i].g * 0.2, btn_colors[i].b * 0.2, 0.8)
		style.border_color = btn_colors[i]
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.pressed.connect(btn_callbacks[i])
		actions.add_child(btn)
	
	return ui

func _update_battle_ui() -> void:
	if not battle_enemy or not battle_ui:
		return
	
	var enemy_name_label = battle_ui.find_child("EnemyName", true, false)
	var enemy_hp_label = battle_ui.find_child("EnemyHP", true, false)
	var enemy_hp_bar = battle_ui.find_child("EnemyHPBar", true, false)
	var player_hp_label = battle_ui.find_child("PlayerHP", true, false)
	var player_hp_bar = battle_ui.find_child("PlayerHPBar", true, false)
	
	if enemy_name_label:
		enemy_name_label.text = battle_enemy.name
	
	if enemy_hp_label:
		enemy_hp_label.text = str(max(0, battle_enemy.hp)) + "/" + str(battle_enemy.get("max_hp", 30))
	
	if enemy_hp_bar:
		var enemy_max_hp = float(battle_enemy.get("max_hp", 30))
		var hp_percent = float(max(0, battle_enemy.hp)) / enemy_max_hp
		enemy_hp_bar.size.x = 200 * clamp(hp_percent, 0.0, 1.0)
	
	if player_hp_label:
		player_hp_label.text = str(player_hp) + "/" + str(player_max_hp)
	
	if player_hp_bar:
		var hp_percent = float(player_hp) / float(player_max_hp)
		player_hp_bar.size.x = 270 * clamp(hp_percent, 0.0, 1.0)


func _show_conversar_button():
	if conversation_options_container:
		conversation_options_container.queue_free()
	conversation_options_container = VBoxContainer.new()
	conversation_options_container.name = "ConversarButtonContainer"
	conversation_options_container.anchor_left = 0.5
	conversation_options_container.anchor_top = 0.7
	conversation_options_container.anchor_right = 0.98
	conversation_options_container.anchor_bottom = 0.98
	var btn = Button.new()
	btn.text = "Conversar"
	btn.pressed.connect(_show_battle_options_in_dialogue)
	conversation_options_container.add_child(btn)
	dialogue_box.add_child(conversation_options_container)

func _show_battle_options_in_dialogue():
	if conversation_options_container:
		conversation_options_container.queue_free()
	conversation_options_container = VBoxContainer.new()
	conversation_options_container.name = "BattleOptionsDialogue"
	conversation_options_container.anchor_left = 0.5
	conversation_options_container.anchor_top = 0.7
	conversation_options_container.anchor_right = 0.98
	conversation_options_container.anchor_bottom = 0.98
	var options = battle_dialogue_rounds[min(current_battle_round, battle_dialogue_rounds.size() - 1)]
	for i in range(len(options)):
		var option = options[i]
		var btn = Button.new()
		btn.text = option.text
		btn.pressed.connect(func(idx=i, opt=option): _on_battle_option_selected(opt, idx))
		conversation_options_container.add_child(btn)

	# Log: opções exibidas (via diálogo)
	if logger:
		logger.log_event("option_displayed", {"dialog_id": current_battle_round}, player_grid_pos.floor())
	dialogue_box.add_child(conversation_options_container)

func _on_conversation_option(option_index: int) -> void:
	conversation_menu_active = false
	conversation_options_container.visible = false
	
	# Mostrar diálogo novamente
	var dialogue_text = battle_ui.find_child("DialogueText", true, false)
	if not dialogue_text:
		return
	
	dialogue_text.visible = true
	
	if option_index == 4:  # Opção "Voltar"
		dialogue_text.text = "* You got lost."
		return
	
	# Respostas baseadas no inimigo e opção escolhida
	if battle_enemy.name == "Espelho":
		match option_index:
			0:  # Quem é você?
				dialogue_text.text = "* O espelho reflete seu próprio olhar...\n* 'Você já sabe a resposta.'"
			1:  # Por que está aqui?
				dialogue_text.text = "* O reflexo parece distorcido...\n* 'Para mostrar a verdade.'"
			2:  # O que você quer de mim?
				dialogue_text.text = "* O espelho brilha intensamente...\n* 'Encarar quem você realmente é.'"
			3:  # Você é real?
				dialogue_text.text = "* O reflexo sorri de forma perturbadora...\n* 'Tão real quanto você.'"
	else:
		dialogue_text.text = "* " + battle_enemy.name + " olha para você silenciosamente..."

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
	var old_player_hp = player_hp
	player_hp -= enemy_damage
	dialogue_text.text = "* " + battle_enemy.name + " attacks!\n* You took " + str(enemy_damage) + " damage!"
	_update_battle_ui()

	# Log de mudança de HP do jogador e marcar que sofreu dano (para reações)
	if logger and player_hp != old_player_hp:
		logger.log_state("heath_changed", {"who": "player", "old_health_value": old_player_hp, "option_number": last_selected_option_index}, player_grid_pos.floor())
		recently_damaged = true
	
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

	# Desenhar objetos do mapa (NPCs, itens)
	if map.has("objects"):
		for obj in map.objects:
			draw_list.append({"pos": obj.pos, "type": "npc", "depth": obj.pos.x + obj.pos.y, "data": obj})
	
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
		elif item.type == "npc":
			_draw_npc(screen_pos, item.data)
		elif item.type == "player":
			_draw_player_sprite(screen_pos, Color.CYAN)

func _draw_npc(pos: Vector2, _obj: Dictionary) -> void:
	# Desenhar NPC igual ao player, mas em verde
	var head_pos = pos + Vector2(0, -(PLAYER_HEIGHT + PLAYER_HEAD_RADIUS))
	draw_circle(head_pos, PLAYER_HEAD_RADIUS, Color(0, 1, 0))

	var body_points = PackedVector2Array([
		pos + Vector2(-PLAYER_WIDTH / 2.0, -PLAYER_HEIGHT),
		pos + Vector2(PLAYER_WIDTH / 2.0, -PLAYER_HEIGHT),
		pos + Vector2(PLAYER_WIDTH / 2.0, 0),
		pos + Vector2(-PLAYER_WIDTH / 2.0, 0)
	])
	draw_polygon(body_points, PackedColorArray([Color(0, 0.7, 0)]))

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

func _draw_enemy(pos: Vector2, _enemy: Dictionary) -> void:
	var enemy_pos = pos + Vector2(0, -20)
	draw_circle(enemy_pos, 15, Color.RED)
