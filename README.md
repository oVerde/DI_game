# DJ Game - RPG Isométrico

## 📋 Descrição
Jogo RPG com perspectiva isométrica estilo Hades e sistema de batalha inspirado em Undertale.

## 🎮 Como Jogar

### Menu Inicial
- **PLAY**: Inicia o jogo
- **SETTINGS**: Ajusta configurações (volume, qualidade, etc.)
- **QUIT**: Fecha o jogo

### Exploração
- **W, A, S, D**: Movimento em perspectiva isométrica
- **E**: Interagir com portas e inimigos

### Batalha
- **FIGHT**: Atacar o inimigo
- **ACT**: (Em desenvolvimento)
- **ITEM**: (Em desenvolvimento)
- **MERCY**: Fugir da batalha

## 📁 Estrutura do Projeto

```
DJ_game-main/
├── scenes/
│   ├── menu/
│   │   └── main_menu.tscn       # Menu inicial
│   ├── game/
│   │   └── game_scene.tscn      # Cena principal do jogo
│   └── ui/
│       └── battle_ui.tscn       # (Futuro) UI de batalha separada
├── scripts/
│   ├── menu/
│   │   └── menu_manager.gd      # Lógica do menu
│   ├── game/
│   │   ├── game_manager.gd      # Gerenciador principal
│   │   ├── player.gd            # Controle do jogador
│   │   └── camera_controller.gd # Controle de câmera
│   ├── map/
│   │   ├── map_data.gd          # Dados dos mapas
│   │   ├── map_loader.gd        # Carregamento de mapas
│   │   └── map_renderer.gd      # Renderização isométrica
│   ├── battle/
│   │   ├── battle_manager.gd    # Sistema de batalha
│   │   └── battle_ui.gd         # Interface de batalha
│   └── utils/
│       └── isometric_utils.gd   # Funções de conversão isométrica
├── data/
│   └── maps/
│       ├── map_01_sala_inicial.tres
│       ├── map_02_corredor.tres
│       └── map_03_sala_chefe.tres
├── multimedia/
│   ├── background.ogv           # Vídeo de fundo do menu
│   └── logo.png                 # Logo do jogo
├── game.gd                      # (Atual) Script monolítico - será refatorado
├── test.gd                      # Script do menu
└── README.md                    # Este arquivo
```

## 🗺️ Mapas

### Mapa 1: Sala Inicial
- **Tamanho**: 15x10
- **Spawn**: (2, 5)
- **Saídas**: Porta Leste → Mapa 2

### Mapa 2: Corredor
- **Tamanho**: 20x10
- **Spawn**: (2, 5)
- **Saídas**: 
  - Porta Oeste → Mapa 1
  - Porta Leste → Mapa 3

### Mapa 3: Sala do Chefe
- **Tamanho**: 15x12
- **Spawn**: (2, 6)
- **Inimigos**: Slime (HP: 30, ATK: 5)
- **Saídas**: Porta Oeste → Mapa 2

## 🎯 Sistema de Combate

### Estatísticas do Jogador
- **HP Máximo**: 100
- **Ataque**: 10
- **Nível**: 19 (visual apenas)

### Mecânicas de Batalha
1. Jogador ataca primeiro
2. Dano = Ataque Base + (0-4 aleatório)
3. Inimigo contra-ataca se sobreviver
4. Vitória: Inimigo desaparece do mapa
5. Derrota: Jogador retorna ao Mapa 1 com HP cheio

## 🔧 Configurações Salvas

As configurações são salvas em `user://settings.cfg`:
- Master Volume
- Music Volume
- SFX Volume
- Video Quality
- VSync
- Resolution Scale
- Invert Y Controls

## 📝 Roadmap

### ✅ Implementado
- [x] Menu principal com vídeo de fundo
- [x] Sistema de configurações persistentes
- [x] Movimento isométrico WASD
- [x] Sistema de múltiplos mapas
- [x] Portas entre mapas
- [x] Sistema de batalha estilo Undertale
- [x] UI de batalha completa
- [x] Interação com inimigos

### 🚧 Em Desenvolvimento
- [ ] Separação de scripts em módulos
- [ ] Sistema de recursos para mapas
- [ ] Botões ACT e ITEM funcionais
- [ ] Diferentes tipos de inimigos
- [ ] Sistema de inventário
- [ ] Sistema de XP e Level Up

### 🔮 Futuro
- [ ] Mais mapas
- [ ] Sistema de quests
- [ ] NPCs e diálogos
- [ ] Sistema de save/load
- [ ] Música e efeitos sonoros
- [ ] Sprites personalizados

## 🛠️ Tecnologias
- **Engine**: Godot 4.5
- **Linguagem**: GDScript
- **Perspectiva**: Isométrica 2D (45°)

## 📌 Notas Técnicas

### Conversão Isométrica
```gdscript
func cartesian_to_isometric(cart: Vector2) -> Vector2:
    return Vector2(
        (cart.x - cart.y) * TILE_WIDTH_HALF,
        (cart.x + cart.y) * TILE_HEIGHT_HALF
    )
```

### Movimento Isométrico
O input é convertido para movimento na grade:
- W/S controla Y
- A/D controla X
- Transformação: `move_vector.x = input.x + input.y`
- Transformação: `move_vector.y = input.y - input.x`

## 🤝 Contribuindo
Este é um projeto em desenvolvimento. Sugestões e melhorias são bem-vindas!

## 📄 Licença
[Definir licença]
