extends Node
class_name BattleManager

## Sistema de batalha estilo Undertale
## Gerencia o estado da batalha, UI e ações

signal battle_ended(victory: bool)

# Referências
var ui_container: Control
var player_stats: Dictionary
var enemy_stats: Dictionary

# Estado
var is_active: bool = false

# Constantes de UI
const UI_BLACK := Color(0, 0, 0, 1)
const UI_WHITE := Color(1, 1, 1, 1)
const BUTTON_RED := Color(0.8, 0.2, 0.2, 1)
const BUTTON_BLUE := Color(0.2, 0.5, 0.9, 1)
const BUTTON_YELLOW := Color(0.9, 0.7, 0.2, 1)
const BUTTON_PINK := Color(0.9, 0.4, 0.7, 1)

func _ready():
	pass

## Inicializa uma nova batalha
func start_battle(p_stats: Dictionary, e_stats: Dictionary, parent: Control):
	player_stats = p_stats.duplicate()
	enemy_stats = e_stats.duplicate()
	ui_container = parent
	is_active = true
	
	_create_ui()

## Cria a interface de batalha estilo Undertale
func _create_ui():
	# Fundo preto
	var background := ColorRect.new()
	background.name = "BattleBackground"
	background.color = UI_BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_container.add_child(background)
	
	# Container principal centralizado
	var main_container := Control.new()
	main_container.name = "BattleMainContainer"
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.size = Vector2(640, 480)
	main_container.position = Vector2(-320, -240)
	background.add_child(main_container)
	
	# Informações do inimigo
	var enemy_label := Label.new()
	enemy_label.name = "EnemyLabel"
	enemy_label.text = enemy_stats["name"] + " apareceu!"
	enemy_label.position = Vector2(50, 30)
	enemy_label.add_theme_color_override("font_color", UI_WHITE)
	main_container.add_child(enemy_label)
	
	# HP do inimigo
	var enemy_hp := Label.new()
	enemy_hp.name = "EnemyHP"
	enemy_hp.text = "HP: %d/%d" % [enemy_stats["hp"], enemy_stats["max_hp"]]
	enemy_hp.position = Vector2(50, 60)
	enemy_hp.add_theme_color_override("font_color", UI_WHITE)
	main_container.add_child(enemy_hp)
	
	# Caixa de batalha (branca)
	var battle_box := Panel.new()
	battle_box.name = "BattleBox"
	battle_box.position = Vector2(50, 240)
	battle_box.size = Vector2(540, 155)
	
	var battle_style := StyleBoxFlat.new()
	battle_style.bg_color = UI_BLACK
	battle_style.border_color = UI_WHITE
	battle_style.set_border_width_all(3)
	battle_box.add_theme_stylebox_override("panel", battle_style)
	main_container.add_child(battle_box)
	
	# Container dos botões
	var buttons_container := Control.new()
	buttons_container.name = "ButtonsContainer"
	buttons_container.position = Vector2(0, 0)
	buttons_container.size = Vector2(540, 155)
	battle_box.add_child(buttons_container)
	
	# Criar os 4 botões
	_create_battle_button(buttons_container, "* FIGHT", 30, 20, BUTTON_RED, _on_attack_pressed, battle_style)
	_create_battle_button(buttons_container, "* ACT", 290, 20, BUTTON_BLUE, _on_act_pressed, battle_style)
	_create_battle_button(buttons_container, "* ITEM", 30, 85, BUTTON_YELLOW, _on_item_pressed, battle_style)
	_create_battle_button(buttons_container, "* MERCY", 290, 85, BUTTON_PINK, _on_flee_pressed, battle_style)
	
	# HP do jogador
	var player_hp_label := Label.new()
	player_hp_label.name = "PlayerHPLabel"
	player_hp_label.text = "LV 19    HP"
	player_hp_label.position = Vector2(70, 410)
	player_hp_label.add_theme_color_override("font_color", UI_WHITE)
	main_container.add_child(player_hp_label)
	
	# Barra de HP
	var hp_bar_bg := ColorRect.new()
	hp_bar_bg.name = "HPBarBG"
	hp_bar_bg.color = Color(0.8, 0, 0, 1)
	hp_bar_bg.position = Vector2(220, 413)
	hp_bar_bg.size = Vector2(200, 24)
	main_container.add_child(hp_bar_bg)
	
	var hp_bar := ColorRect.new()
	hp_bar.name = "HPBar"
	hp_bar.color = Color(1, 1, 0, 1)
	hp_bar.position = Vector2(0, 0)
	var hp_percent := float(player_stats["hp"]) / float(player_stats["max_hp"])
	hp_bar.size = Vector2(200 * hp_percent, 24)
	hp_bar_bg.add_child(hp_bar)
	
	# Texto de HP numérico
	var hp_text := Label.new()
	hp_text.name = "HPText"
	hp_text.text = "%d / %d" % [player_stats["hp"], player_stats["max_hp"]]
	hp_text.position = Vector2(430, 410)
	hp_text.add_theme_color_override("font_color", UI_WHITE)
	main_container.add_child(hp_text)
	
	# Texto de diálogo
	var dialogue := Label.new()
	dialogue.name = "BattleDialogue"
	dialogue.text = "O que você vai fazer?"
	dialogue.position = Vector2(70, 260)
	dialogue.add_theme_color_override("font_color", UI_WHITE)
	main_container.add_child(dialogue)

## Cria um botão de batalha estilizado
func _create_battle_button(container: Control, text: String, pos_x: float, pos_y: float, 
							btn_color: Color, callback: Callable, base_style: StyleBoxFlat):
	var button := Button.new()
	button.text = text
	button.position = Vector2(pos_x, pos_y)
	button.size = Vector2(230, 50)
	
	var style := base_style.duplicate()
	style.bg_color = btn_color
	style.border_color = UI_WHITE
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", UI_WHITE)
	
	button.pressed.connect(callback)
	container.add_child(button)

## Atualiza a UI da batalha
func _update_ui():
	var main_container = ui_container.find_child("BattleMainContainer", true, false)
	if not main_container:
		return
	
	# Atualizar HP do inimigo
	var enemy_hp_label = main_container.find_child("EnemyHP", true, false)
	if enemy_hp_label:
		enemy_hp_label.text = "HP: %d/%d" % [enemy_stats["hp"], enemy_stats["max_hp"]]
	
	# Atualizar HP do jogador
	var hp_bar_bg = main_container.find_child("HPBarBG", true, false)
	if hp_bar_bg:
		var hp_bar = hp_bar_bg.find_child("HPBar", true, false)
		if hp_bar:
			var hp_percent := float(player_stats["hp"]) / float(player_stats["max_hp"])
			hp_bar.size.x = 200 * hp_percent
	
	var hp_text = main_container.find_child("HPText", true, false)
	if hp_text:
		hp_text.text = "%d / %d" % [player_stats["hp"], player_stats["max_hp"]]

## Atualiza o texto de diálogo
func _update_dialogue(message: String):
	var main_container = ui_container.find_child("BattleMainContainer", true, false)
	if not main_container:
		return
	
	var dialogue = main_container.find_child("BattleDialogue", true, false)
	if dialogue:
		dialogue.text = message

## Ação: Atacar
func _on_attack_pressed():
	var damage := player_stats["attack"] + randi() % 5
	enemy_stats["hp"] -= damage
	
	_update_dialogue("Você causou %d de dano!" % damage)
	_update_ui()
	
	if enemy_stats["hp"] <= 0:
		await get_tree().create_timer(1.0).timeout
		_end_battle(true)
		return
	
	# Turno do inimigo
	await get_tree().create_timer(1.5).timeout
	_enemy_turn()

## Ação: ACT (placeholder)
func _on_act_pressed():
	_update_dialogue("* ACT em desenvolvimento...")

## Ação: ITEM (placeholder)
func _on_item_pressed():
	_update_dialogue("* ITEM em desenvolvimento...")

## Ação: Fugir
func _on_flee_pressed():
	_update_dialogue("Você fugiu da batalha!")
	await get_tree().create_timer(1.0).timeout
	_end_battle(false)

## Turno do inimigo
func _enemy_turn():
	var damage := enemy_stats["attack"] + randi() % 3
	player_stats["hp"] -= damage
	
	_update_dialogue("%s te atacou! -%d HP" % [enemy_stats["name"], damage])
	_update_ui()
	
	if player_stats["hp"] <= 0:
		await get_tree().create_timer(1.0).timeout
		_end_battle(false)
		return
	
	await get_tree().create_timer(1.5).timeout
	_update_dialogue("O que você vai fazer?")

## Finaliza a batalha
func _end_battle(victory: bool):
	is_active = false
	
	# Limpar UI
	var background = ui_container.find_child("BattleBackground", true, false)
	if background:
		background.queue_free()
	
	battle_ended.emit(victory)

## Retorna estatísticas atualizadas do jogador
func get_player_stats() -> Dictionary:
	return player_stats
