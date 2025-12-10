extends Node

# --- Configurações Visuais ---
# Caminho da fonte (ex: "res://fonts/minha_fonte.ttf"). Deixe vazio para usar a padrão.
var custom_font_path: String = "" 

# Cores (Tons de Branco)
var color_normal: Color = Color(0.9, 0.9, 0.9, 0.7) # Branco levemente transparente
var color_hover: Color = Color(1.0, 1.0, 1.0, 1.0) # Branco puro brilhante
var color_pressed: Color = Color(0.7, 0.7, 0.7, 1.0) # Cinza claro

# Animação
var anim_move_amount: float = -30.0 # Move 30 pixels para a esquerda (para dentro)
var anim_duration: float = 0.2

# --- Nós ---
var video_player: VideoStreamPlayer
var menu_container: VBoxContainer
var buttons: Array[Button] = []
var control_root: Control

func _ready() -> void:
	print("Iniciando Menu...")
	
	# Cria uma CanvasLayer para garantir que a UI apareça na frente de tudo
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	# Cria o Control raiz para a UI
	control_root = Control.new()
	control_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(control_root)
	
	# 1. Configurar Vídeo de Fundo
	_setup_video_background()
	
	# 2. Configurar Menu de Botões
	_setup_menu_buttons()
	
	# 3. Configurar Logo
	_setup_logo()
	
	# Foca no primeiro botão para navegação por teclado
	if buttons.size() > 0:
		buttons[0].grab_focus()
	
	print("Menu iniciado. Adicione um vídeo em 'res://multimedia/video.ogv' para ver o fundo.")

func _process(_delta: float) -> void:
	# Loop do vídeo manual (garantia)
	if video_player and not video_player.is_playing():
		video_player.play()

func _setup_video_background() -> void:
	# Fundo base (Cinza escuro para debug - se ver isso, o vídeo falhou)
	var bg_color = ColorRect.new()
	bg_color.color = Color(0.1, 0.1, 0.15) # Cinza azulado escuro
	bg_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	control_root.add_child(bg_color)
	
	# Player de Vídeo
	video_player = VideoStreamPlayer.new()
	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE # Não bloquear cliques
	
	# Tenta carregar o vídeo
	# Nota: Godot tem melhor suporte para .ogv (Ogg Theora). Se .mp4 não tocar, converta para .ogv.
	var video_path = "res://multimedia/background.ogv"
	if not ResourceLoader.exists(video_path):
		# Tenta nome alternativo caso o usuário tenha mudado
		video_path = "res://multimedia/video.ogv"
	
	if ResourceLoader.exists(video_path):
		var stream = load(video_path)
		video_player.stream = stream
		video_player.autoplay = true
		video_player.play()
		print("Vídeo encontrado e carregado: ", video_path)
		print("Se a tela estiver preta/cinza, o Godot não conseguiu decodificar o MP4.")
		print("SOLUÇÃO: Converta o vídeo para .ogv (Ogg Theora).")
	else:
		print("AVISO: Vídeo não encontrado. Esperado: res://multimedia/background_menu.mp4")
	
	control_root.add_child(video_player)
	
	# Overlay escuro para melhorar leitura dos botões (opcional, mas recomendado)
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.2) # 20% preto
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control_root.add_child(overlay)

func _setup_logo() -> void:
	var logo_path = "res://multimedia/logo.png"
	if not ResourceLoader.exists(logo_path):
		print("Logo não encontrado em ", logo_path)
		return

	var texture = load(logo_path)
	var logo_rect = TextureRect.new()
	logo_rect.texture = texture
	# Mantém a proporção e centraliza na área definida
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Posicionamento: Lado Esquerdo (Ocupa 40% da largura da tela)
	logo_rect.anchor_left = 0.05  # Margem esquerda de 5%
	logo_rect.anchor_top = 0.1    # Margem superior de 10%
	logo_rect.anchor_right = 0.45 # Vai até 45% da largura
	logo_rect.anchor_bottom = 0.9 # Margem inferior de 10%
	
	# Transparência
	logo_rect.modulate.a = 0.8 # 80% visível (ajuste conforme necessário)
	
	control_root.add_child(logo_rect)

func _setup_menu_buttons() -> void:
	# Container vertical para os botões
	menu_container = VBoxContainer.new()
	menu_container.alignment = BoxContainer.ALIGNMENT_END # Alinha itens no fundo do container
	
	# Posicionamento: Canto Inferior Direito
	# Âncoras definem a área que o container ocupa
	menu_container.anchor_left = 0.7   # Começa em 70% da largura
	menu_container.anchor_top = 0.35   # Começa em 35% da altura
	menu_container.anchor_right = 1.0  # Vai até 100% da largura (Sem margem direita)
	menu_container.anchor_bottom = 0.85 # Vai até 85% da altura
	
	# Espaçamento entre botões
	menu_container.add_theme_constant_override("separation", 15)
	
	control_root.add_child(menu_container)
	
	# Criar os botões
	_create_animated_button("PLAY", "play")
	_create_animated_button("SETTINGS", "settings")
	_create_animated_button("QUIT", "quit")

func _create_animated_button(text: String, action_name: String) -> void:
	# Para animar a posição X sem que o VBoxContainer interfira,
	# criamos um Control "Holder" invisível que fica no VBox.
	# O Botão será filho desse Holder e poderá se mover livremente dentro dele.
	
	var holder = Control.new()
	holder.custom_minimum_size = Vector2(0, 60) # Altura reservada para o botão
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE # Deixa o mouse passar para o botão
	menu_container.add_child(holder)
	
	# --- Fundo Degradê (Sombra) ---
	# Cria um degradê preto -> transparente (Direita -> Esquerda)
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0.9)) # Direita: Preto quase sólido (Offset 0)
	gradient.set_color(1, Color(0, 0, 0, 0))   # Esquerda: Transparente (Offset 1)
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(1, 0) # Começa na direita (Offset 0)
	gradient_texture.fill_to = Vector2(0, 0)   # Vai para a esquerda (Offset 1)
	
	var bg_rect = TextureRect.new()
	bg_rect.texture = gradient_texture
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.modulate.a = 0.0 # Começa invisível
	holder.add_child(bg_rect)
	
	# --- Botão ---
	var btn = Button.new()
	btn.text = text
	btn.name = action_name
	btn.flat = true # Remove bordas padrão
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER # Texto centralizado no botão
	
	# Remove estilos padrão (fundo/bordas) para evitar "quadrados brancos"
	var style_empty = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", style_empty)
	btn.add_theme_stylebox_override("hover", style_empty)
	btn.add_theme_stylebox_override("pressed", style_empty)
	btn.add_theme_stylebox_override("focus", style_empty)
	
	# Configurações de Fonte e Cor
	btn.add_theme_font_size_override("font_size", 42)
	btn.add_theme_color_override("font_color", color_normal)
	btn.add_theme_color_override("font_focus_color", color_hover)
	btn.add_theme_color_override("font_hover_color", color_hover)
	btn.add_theme_color_override("font_pressed_color", color_pressed)
	
	if custom_font_path != "" and ResourceLoader.exists(custom_font_path):
		var font = load(custom_font_path)
		btn.add_theme_font_override("font", font)
	
	# Posicionamento dentro do Holder (Preenche todo o espaço para centralizar o texto no degradê)
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Salva referência do fundo no botão para animar depois
	btn.set_meta("background", bg_rect)
	
	holder.add_child(btn)
	buttons.append(btn)
	
	# Conectar Sinais para Animação e Ação
	btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
	btn.mouse_exited.connect(_on_button_hover.bind(btn, false))
	btn.focus_entered.connect(_on_button_hover.bind(btn, true))
	btn.focus_exited.connect(_on_button_hover.bind(btn, false))
	btn.pressed.connect(_on_button_pressed.bind(action_name))

func _on_button_hover(btn: Button, hovered: bool) -> void:
	# Cria uma animação suave (Tween)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	var bg_rect = btn.get_meta("background") as TextureRect
	
	if hovered:
		# Move para a esquerda (anim_move_amount é negativo)
		# Mantém a largura constante movendo ambos os offsets
		tween.tween_property(btn, "offset_left", anim_move_amount, anim_duration)
		tween.tween_property(btn, "offset_right", anim_move_amount, anim_duration)
		
		# Aparece o fundo degradê
		tween.tween_property(bg_rect, "modulate:a", 1.0, anim_duration)
	else:
		# Volta para a posição original (0)
		tween.tween_property(btn, "offset_left", 0.0, anim_duration)
		tween.tween_property(btn, "offset_right", 0.0, anim_duration)
		
		# Esconde o fundo degradê
		tween.tween_property(bg_rect, "modulate:a", 0.0, anim_duration)


func _on_button_pressed(action: String) -> void:
	print("Botão pressionado: ", action)
	match action:
		"play":
			print("Iniciar Jogo...")
			# Esconde o menu
			control_root.visible = false
			
			# Inicia o jogo isométrico
			var game = load("res://isometric_game.gd").new()
			add_child(game)
			
		"settings":
			print("Abrir Configurações...")
		"quit":
			print("Saindo...")
			get_tree().quit()

func soma(a: int, b: int) -> int:
	return a + b
