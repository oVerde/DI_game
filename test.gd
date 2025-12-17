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
var settings_container: Control
var main_menu_container: Control
var is_in_settings: bool = false

# --- Configurações do Jogo ---
const SETTINGS_FILE = "user://settings.cfg"

var game_settings = {
	"master_volume": 0.8,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"video_quality": "high",  # low, medium, high
	"vsync_enabled": true,
	"resolution_scale": 1.0,
	"controls_invert_y": false
}

func _ready() -> void:
	print("Iniciando Menu...")
	
	# Carrega configurações salvas
	_load_settings()
	
	# Limpa qualquer estado anterior
	buttons.clear()
	is_in_settings = false
	
	# Limpa nós antigos se existirem
	if is_instance_valid(control_root):
		control_root.queue_free()
	
	# Cria uma CanvasLayer para garantir que a UI apareça na frente de tudo
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	# Cria o Control raiz para a UI
	control_root = Control.new()
	control_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(control_root)
	
	# 1. Configurar Vídeo de Fundo
	_setup_video_background()
	
	# 2. Configurar Menu de Botões (guardar referência)
	main_menu_container = Control.new()
	control_root.add_child(main_menu_container)
	_setup_menu_buttons()
	
	# 3. Configurar Logo
	_setup_logo()
	
	# 4. Criar Container de Settings (escondido inicialmente)
	settings_container = Control.new()
	settings_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_container.visible = false
	control_root.add_child(settings_container)
	
	# Foca no primeiro botão para navegação por teclado
	if buttons.size() > 0 and is_instance_valid(buttons[0]):
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
			# Carrega a cena do jogo
			get_tree().change_scene_to_file("res://game_scene.tscn")
			
		"settings":
			print("Abrir Configurações...")
			if is_instance_valid(main_menu_container) and is_instance_valid(settings_container):
				_transition_to_settings()
		"quit":
			print("Saindo...")
			get_tree().quit()

func _transition_to_settings() -> void:
	# Fade out cascata do menu principal e logo
	_fade_out_menu()
	await get_tree().create_timer(1.2).timeout  # Aguarda fade out completo
	
	if not is_instance_valid(main_menu_container):
		return
	
	main_menu_container.visible = false
	
	if not is_instance_valid(settings_container):
		return
	
	_show_settings()
	
	# Fade in cascata do settings
	_fade_in_settings()

func _fade_out_menu() -> void:
	# Fade out dos botões em cascata
	for i in range(buttons.size()):
		var btn = buttons[i]
		if not is_instance_valid(btn):
			continue
		
		await get_tree().create_timer(i * 0.1).timeout
		
		if not is_instance_valid(btn):  # Verifica novamente após delay
			continue
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(btn, "modulate:a", 0.0, 0.3)
	
	# Fade out do logo
	var logo = _get_logo()
	if is_instance_valid(logo):
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(logo):  # Verifica novamente após delay
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_ease(Tween.EASE_IN)
			tween.tween_property(logo, "modulate:a", 0.0, 0.3)

func _fade_in_settings() -> void:
	# Fade in cascata dos elementos do settings
	var settings_elements = settings_container.get_children()
	var delay = 0.0
	
	for element in settings_elements:
		if not is_instance_valid(element):
			continue
		
		if not element.visible:
			continue
		
		await get_tree().create_timer(delay).timeout
		
		if not is_instance_valid(element):  # Verifica novamente após delay
			continue
		
		element.modulate.a = 0.0
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(element, "modulate:a", 1.0, 0.3)
		
		delay += 0.08

func _show_settings() -> void:
	is_in_settings = true
	main_menu_container.visible = false
	settings_container.visible = true
	
	# Limpa container anterior
	for child in settings_container.get_children():
		child.queue_free()
	
	# Cria overlay escuro
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.2)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_container.add_child(overlay)
	
	# Container principal - Centrado na tela e encostado à esquerda
	var main_container = VBoxContainer.new()
	main_container.anchor_left = 0.05   # 5% de margem esquerda
	main_container.anchor_top = 0.05    # 5% de margem superior
	main_container.anchor_right = 0.6   # Até 60% da tela (content na esquerda)
	main_container.anchor_bottom = 0.95 # 95% de altura
	main_container.add_theme_constant_override("separation", 15)
	settings_container.add_child(main_container)
	
	# Container horizontal para título e botão back
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)
	header.custom_minimum_size = Vector2(0, 70)
	main_container.add_child(header)
	
	# Botão Back (à esquerda do título)
	var back_button = Button.new()
	back_button.text = "◀"
	back_button.custom_minimum_size = Vector2(70, 60)
	back_button.add_theme_font_size_override("font_size", 24)
	back_button.add_theme_color_override("font_color", color_normal)
	back_button.add_theme_color_override("font_hover_color", color_hover)
	back_button.add_theme_color_override("font_pressed_color", color_pressed)
	back_button.pressed.connect(_on_settings_back)
	header.add_child(back_button)
	
	# Título
	var title = Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 50)
	title.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(title)
	
	# Linha separadora visual
	var separator = Control.new()
	separator.custom_minimum_size = Vector2(0, 2)
	main_container.add_child(separator)
	
	# Som
	_add_settings_category(main_container, "SOUND")
	_add_volume_slider(main_container, "Master Volume", "master_volume")
	_add_volume_slider(main_container, "Music Volume", "music_volume")
	_add_volume_slider(main_container, "SFX Volume", "sfx_volume")
	
	# Espaço
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	main_container.add_child(spacer)
	
	# Vídeo
	_add_settings_category(main_container, "VIDEO")
	_add_quality_button(main_container)
	_add_vsync_toggle(main_container)
	_add_resolution_slider(main_container)
	
	# Espaço
	spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	main_container.add_child(spacer)
	
	# Controlos
	_add_settings_category(main_container, "CONTROLS")
	_add_invert_y_toggle(main_container)
func _add_settings_category(container: VBoxContainer, title: String) -> void:
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	label.modulate.a = 0.0  # Começa invisível para animação
	container.add_child(label)

func _add_volume_slider(container: VBoxContainer, label_text: String, setting_key: String) -> void:
	var h_box = HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 15)
	h_box.custom_minimum_size = Vector2(0, 45)
	
	# Label
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	label.custom_minimum_size = Vector2(220, 0)
	h_box.add_child(label)
	
	# Slider
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = game_settings[setting_key]
	slider.custom_minimum_size = Vector2(200, 40)
	h_box.add_child(slider)
	
	# Valor (%)
	var value_label = Label.new()
	value_label.text = str(int(game_settings[setting_key] * 100)) + "%"
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	value_label.custom_minimum_size = Vector2(60, 0)
	h_box.add_child(value_label)
	
	# Conectar mudanças do slider
	slider.value_changed.connect(func(val):
		game_settings[setting_key] = val
		value_label.text = str(int(val * 100)) + "%"
		_apply_audio_settings(setting_key, val)
		_save_settings()
	)
	
	container.add_child(h_box)

func _add_quality_button(container: VBoxContainer) -> void:
	var h_box = HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 15)
	h_box.custom_minimum_size = Vector2(0, 45)
	
	# Label
	var label = Label.new()
	label.text = "Video Quality"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	label.custom_minimum_size = Vector2(220, 0)
	h_box.add_child(label)
	
	# Botões de qualidade
	var quality_options = ["Low", "Medium", "High"]
	var current_quality = game_settings["video_quality"]
	var quality_index = quality_options.find(current_quality.capitalize())
	
	for i in range(quality_options.size()):
		var btn = Button.new()
		btn.text = quality_options[i]
		btn.custom_minimum_size = Vector2(90, 40)
		btn.add_theme_font_size_override("font_size", 16)
		
		if i == quality_index:
			btn.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		else:
			btn.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		
		btn.pressed.connect(func():
			game_settings["video_quality"] = quality_options[i].to_lower()
			_refresh_quality_buttons(h_box, quality_options, i)
			_save_settings()
		)
		h_box.add_child(btn)
	
	container.add_child(h_box)

func _refresh_quality_buttons(container: HBoxContainer, _options: Array, selected_index: int) -> void:
	var buttons_in_box = container.get_children().slice(1)
	for i in range(buttons_in_box.size()):
		var btn = buttons_in_box[i]
		if i == selected_index:
			btn.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		else:
			btn.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))

func _add_vsync_toggle(container: VBoxContainer) -> void:
	var h_box = HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 15)
	h_box.custom_minimum_size = Vector2(0, 45)
	
	# Label
	var label = Label.new()
	label.text = "VSync"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	label.custom_minimum_size = Vector2(220, 0)
	h_box.add_child(label)
	
	# Toggle Button
	var toggle_btn = Button.new()
	toggle_btn.text = "ON" if game_settings["vsync_enabled"] else "OFF"
	toggle_btn.custom_minimum_size = Vector2(90, 40)
	toggle_btn.add_theme_font_size_override("font_size", 16)
	toggle_btn.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2) if game_settings["vsync_enabled"] else Color(0.9, 0.2, 0.2))
	
	toggle_btn.pressed.connect(func():
		game_settings["vsync_enabled"] = not game_settings["vsync_enabled"]
		toggle_btn.text = "ON" if game_settings["vsync_enabled"] else "OFF"
		toggle_btn.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2) if game_settings["vsync_enabled"] else Color(0.9, 0.2, 0.2))
		_save_settings()
	)
	h_box.add_child(toggle_btn)
	
	container.add_child(h_box)

func _add_resolution_slider(container: VBoxContainer) -> void:
	var h_box = HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 15)
	h_box.custom_minimum_size = Vector2(0, 45)
	
	# Label
	var label = Label.new()
	label.text = "Resolution Scale"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	label.custom_minimum_size = Vector2(220, 0)
	h_box.add_child(label)
	
	# Slider
	var slider = HSlider.new()
	slider.min_value = 0.5
	slider.max_value = 2.0
	slider.step = 0.25
	slider.value = game_settings["resolution_scale"]
	slider.custom_minimum_size = Vector2(200, 40)
	slider.value_changed.connect(func(val): 
		game_settings["resolution_scale"] = val
		_save_settings()
	)
	h_box.add_child(slider)
	
	# Valor (%)
	var value_label = Label.new()
	value_label.text = str(int(game_settings["resolution_scale"] * 100)) + "%"
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	value_label.custom_minimum_size = Vector2(60, 0)
	h_box.add_child(value_label)
	
	slider.value_changed.connect(func(val): value_label.text = str(int(val * 100)) + "%")
	
	container.add_child(h_box)

func _add_invert_y_toggle(container: VBoxContainer) -> void:
	var h_box = HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 15)
	h_box.custom_minimum_size = Vector2(0, 45)
	
	# Label
	var label = Label.new()
	label.text = "Invert Y Axis"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	label.custom_minimum_size = Vector2(220, 0)
	h_box.add_child(label)
	
	# Toggle Button
	var toggle_btn = Button.new()
	toggle_btn.text = "ON" if game_settings["controls_invert_y"] else "OFF"
	toggle_btn.custom_minimum_size = Vector2(90, 40)
	toggle_btn.add_theme_font_size_override("font_size", 16)
	toggle_btn.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2) if game_settings["controls_invert_y"] else Color(0.9, 0.2, 0.2))
	
	toggle_btn.pressed.connect(func():
		game_settings["controls_invert_y"] = not game_settings["controls_invert_y"]
		toggle_btn.text = "ON" if game_settings["controls_invert_y"] else "OFF"
		toggle_btn.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2) if game_settings["controls_invert_y"] else Color(0.9, 0.2, 0.2))
		_save_settings()
	)
	h_box.add_child(toggle_btn)
	
	container.add_child(h_box)

func _create_settings_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 60)
	btn.add_theme_font_size_override("font_size", 36)
	btn.add_theme_color_override("font_color", color_normal)
	btn.add_theme_color_override("font_hover_color", color_hover)
	btn.add_theme_color_override("font_pressed_color", color_pressed)
	return btn

func _on_settings_back() -> void:
	if not is_instance_valid(settings_container):
		return
	
	is_in_settings = false
	
	# Fade out cascata do settings
	var settings_elements = settings_container.get_children()
	var delay = 0.0
	
	for element in settings_elements:
		if not is_instance_valid(element):
			continue
		
		if element.visible:
			await get_tree().create_timer(delay).timeout
			
			if not is_instance_valid(element):  # Verifica novamente
				continue
			
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_ease(Tween.EASE_IN)
			tween.tween_property(element, "modulate:a", 0.0, 0.3)
			
			delay += 0.08
	
	await get_tree().create_timer(0.3).timeout
	
	if is_instance_valid(settings_container):
		settings_container.visible = false
	if is_instance_valid(main_menu_container):
		main_menu_container.visible = true
	
	# Reconstrói array de botões válidos antes de animar
	var valid_buttons: Array[Button] = []
	for btn in buttons:
		if is_instance_valid(btn):
			valid_buttons.append(btn)
	buttons = valid_buttons
	
	# Fade in cascata do menu e logo
	_fade_in_menu()

func _fade_in_menu() -> void:
	# Reconstrói array para evitar referências inválidas
	var valid_buttons: Array[Button] = []
	for btn in buttons:
		if is_instance_valid(btn):
			valid_buttons.append(btn)
	
	if valid_buttons.is_empty():
		return  # Sem botões válidos, sai
	
	# Fade in dos botões em cascata
	for i in range(valid_buttons.size()):
		var btn = valid_buttons[i]
		
		if not is_instance_valid(btn):
			continue
		
		btn.modulate.a = 0.0
		await get_tree().create_timer(i * 0.1).timeout
		
		if not is_instance_valid(btn):  # Verifica novamente após delay
			continue
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "modulate:a", 1.0, 0.3)
	
	# Fade in do logo
	var logo = _get_logo()
	if is_instance_valid(logo):
		logo.modulate.a = 0.0
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(logo):  # Verifica novamente após delay
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(logo, "modulate:a", 0.8, 0.3)
	
	if valid_buttons.size() > 0 and is_instance_valid(valid_buttons[1]):
		valid_buttons[1].grab_focus()

func _get_logo() -> TextureRect:
	# Procura o logo no control_root
	for child in control_root.get_children():
		if child is TextureRect:
			return child
	return null

# Aplica as configurações de áudio aos buses de áudio do Godot
func _apply_audio_settings(setting_key: String, value: float) -> void:
	# Converte o valor linear (0-1) para decibéis (dB)
	# Volume 0 = -80 dB (silêncio), Volume 1 = 0 dB (máximo)
	var db_value = linear_to_db(value) if value > 0 else -80.0
	
	match setting_key:
		"master_volume":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_value)
		"music_volume":
			# Verifica se o bus "Music" existe, senão usa "Master"
			var music_bus_idx = AudioServer.get_bus_index("Music")
			if music_bus_idx != -1:
				AudioServer.set_bus_volume_db(music_bus_idx, db_value)
		"sfx_volume":
			# Verifica se o bus "SFX" existe, senão usa "Master"
			var sfx_bus_idx = AudioServer.get_bus_index("SFX")
			if sfx_bus_idx != -1:
				AudioServer.set_bus_volume_db(sfx_bus_idx, db_value)

# Salva as configurações em um arquivo
func _save_settings() -> void:
	var config = ConfigFile.new()
	
	for key in game_settings.keys():
		config.set_value("settings", key, game_settings[key])
	
	var err = config.save(SETTINGS_FILE)
	if err != OK:
		print("Erro ao salvar configurações: ", err)
	else:
		print("Configurações salvas com sucesso!")

# Carrega as configurações do arquivo
func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	
	if err != OK:
		print("Arquivo de configurações não encontrado. Usando padrões.")
		# Aplica configurações de áudio padrão
		_apply_audio_settings("master_volume", game_settings["master_volume"])
		return
	
	# Carrega cada configuração do arquivo
	for key in game_settings.keys():
		if config.has_section_key("settings", key):
			game_settings[key] = config.get_value("settings", key)
	
	# Aplica as configurações de áudio carregadas
	_apply_audio_settings("master_volume", game_settings["master_volume"])
	_apply_audio_settings("music_volume", game_settings["music_volume"])
	_apply_audio_settings("sfx_volume", game_settings["sfx_volume"])
	
	print("Configurações carregadas: ", game_settings)
