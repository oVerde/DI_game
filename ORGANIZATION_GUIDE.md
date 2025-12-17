# 🔧 Guia de Organização do Código

Este documento explica a nova estrutura modular do projeto e como trabalhar com ela.

## 📁 Nova Estrutura

### **scripts/utils/**
Utilitários reutilizáveis que não dependem de estado do jogo.

- **isometric_utils.gd**: Conversões de coordenadas e cálculos isométricos
  - `cartesian_to_isometric()`: Grid → Tela
  - `isometric_to_cartesian()`: Tela → Grid
  - `input_to_isometric_movement()`: Converte WASD para movimento no grid
  - `calculate_depth()`: Para ordenação de renderização
  - `is_position_valid()`: Valida limites do mapa

### **scripts/map/**
Sistema de mapas e renderização.

- **map_loader.gd**: Carrega dados dos mapas
  - `load_all_maps()`: Carrega todos os mapas de data/maps/
  - `get_map_count()`: Retorna total de mapas
  - `is_valid_map_index()`: Valida índice de mapa

- **map_renderer.gd**: Renderiza elementos visuais
  - `draw_floor()`: Desenha tiles do chão
  - `draw_walls()`: Desenha paredes
  - `draw_doors()`: Desenha portas
  - `draw_enemies()`: Desenha inimigos
  - `draw_player()`: Desenha jogador
  - `draw_interact_hint()`: Mostra dica "[E] Interagir"
  - `draw_scene_sorted()`: Desenha tudo com depth sorting

### **scripts/battle/**
Sistema de combate.

- **battle_manager.gd**: Gerencia batalhas completas
  - `start_battle()`: Inicia nova batalha
  - `_create_ui()`: Cria UI estilo Undertale
  - `_on_attack_pressed()`: Ação de ataque
  - `_on_flee_pressed()`: Fugir da batalha
  - Signal `battle_ended(victory: bool)`: Emitido ao terminar

### **data/maps/**
Dados estáticos dos mapas.

- **map_01_sala_inicial.gd**: Sala inicial (tutorial)
- **map_02_corredor.gd**: Área de transição
- **map_03_sala_chefe.gd**: Sala com Slime

Cada arquivo exporta um `static func get_data()` com estrutura:
```gdscript
{
	"name": String,
	"size": Vector2,
	"player_spawn": Vector2,
	"walls": Array[Vector2],
	"doors": Array[{"pos": Vector2, "leads_to": int}],
	"enemies": Array[{"pos": Vector2, "name": String, "hp": int, "attack": int}]
}
```

## 🔄 Migração do Código Antigo

### Arquivo Atual: `game.gd` (monolítico)
- ✅ Funcional, mas difícil de manter
- ❌ Tudo em um arquivo de 576 linhas
- ❌ Dados misturados com lógica

### Novo Arquivo: `game_refactored.gd`
- ✅ Usa todos os módulos separados
- ✅ Apenas 250 linhas
- ✅ Fácil de entender e modificar
- ✅ Permite trabalho em paralelo

### Como Migrar

**Opção 1: Substituição Direta**
```bash
# Fazer backup
cp game.gd game_old.gd

# Substituir
mv game_refactored.gd game.gd
```

**Opção 2: Testar Primeiro**
1. Renomeie `game.gd` → `game_old.gd`
2. Renomeie `game_refactored.gd` → `game.gd`
3. Teste o jogo
4. Se houver problemas, reverta

## 🎯 Como Adicionar Novos Mapas

### 1. Criar arquivo de dados
```gdscript
# data/maps/map_04_floresta.gd
extends Resource
class_name MapData04

static func get_data() -> Dictionary:
	return {
		"name": "Floresta Misteriosa",
		"size": Vector2(25, 20),
		"player_spawn": Vector2(12, 10),
		"walls": [],  # Gerado automaticamente
		"doors": [
			{"pos": Vector2(0, 10), "leads_to": 2}  # Volta para Sala do Chefe
		],
		"enemies": [
			{"pos": Vector2(15, 12), "name": "Lobo", "hp": 50, "attack": 8}
		]
	}
```

### 2. Registrar no MapLoader
```gdscript
# scripts/map/map_loader.gd
static func load_all_maps() -> Array:
	var maps := []
	maps.append(MapData01.get_data())
	maps.append(MapData02.get_data())
	maps.append(MapData03.get_data())
	maps.append(MapData04.get_data())  # <-- Adicione aqui
	# ...
	return maps

static func get_map_count() -> int:
	return 4  # <-- Atualize aqui
```

### 3. Conectar porta no mapa anterior
```gdscript
# data/maps/map_03_sala_chefe.gd
"doors": [
	{"pos": Vector2(0, 6), "leads_to": 1},
	{"pos": Vector2(14, 6), "leads_to": 3}  # <-- Nova saída
]
```

## 🎨 Como Modificar Renderização

### Mudar cores
Edite constantes em `scripts/map/map_renderer.gd`:
```gdscript
const COLOR_FLOOR := Color(0.3, 0.3, 0.3, 1)
const COLOR_WALL := Color(0.6, 0.6, 0.6, 1)
const COLOR_PLAYER := Color(0.2, 0.6, 1.0, 1)
```

### Adicionar novos elementos visuais
Crie novo método em `MapRenderer`:
```gdscript
func draw_treasure(treasure_pos: Vector2):
	var iso_pos := IsometricUtils.cartesian_to_isometric(treasure_pos) + camera_offset
	canvas.draw_circle(iso_pos, 8, Color.GOLD)
```

## ⚔️ Como Adicionar Ações de Batalha

### 1. Criar callback no BattleManager
```gdscript
# scripts/battle/battle_manager.gd
func _on_item_pressed():
	# Verificar inventário
	if player_has_potion():
		player_stats["hp"] += 20
		_update_dialogue("Você usou uma poção! +20 HP")
		_update_ui()
```

### 2. Conectar botão na UI
Já está conectado! Apenas implemente a lógica.

## 🐛 Debugging

### Ver o que está sendo renderizado
```gdscript
# No _draw_exploration() de game.gd
print("Desenhando mapa: ", maps[current_map_index]["name"])
print("Player em: ", player_grid_pos)
print("Inimigos: ", maps[current_map_index]["enemies"])
```

### Verificar colisões
```gdscript
# No _is_walkable()
if not result:
	print("Bloqueado em: ", pos)
```

## 📝 Checklist para Trabalho Colaborativo

### Trabalhando em Mapas
- [ ] Criar arquivo em `data/maps/`
- [ ] Adicionar em `MapLoader.load_all_maps()`
- [ ] Atualizar `get_map_count()`
- [ ] Conectar portas em mapas adjacentes
- [ ] Testar transições

### Trabalhando em Batalhas
- [ ] Editar apenas `scripts/battle/battle_manager.gd`
- [ ] Testar com diferentes inimigos
- [ ] Não modificar `game.gd`

### Trabalhando em Renderização
- [ ] Editar apenas `scripts/map/map_renderer.gd`
- [ ] Manter assinatura das funções públicas
- [ ] Adicionar novos métodos se necessário

## 🚀 Próximos Passos Recomendados

1. **Migrar para código refatorado**
   - Testar `game_refactored.gd`
   - Substituir `game.gd` quando confirmado

2. **Separar Player em classe própria**
   - Criar `scripts/game/player.gd`
   - Gerenciar stats, inventário, movimento

3. **Sistema de Inventário**
   - Criar `scripts/game/inventory.gd`
   - Integrar com `BattleManager`

4. **Editor de Mapas Visual**
   - Tool script para criar mapas no editor
   - Exportar para `.tres` ou `.json`

5. **Sistema de Save/Load**
   - Salvar posição, HP, inventário
   - Usar `ConfigFile` ou JSON

## ⚠️ Regras Importantes

1. **NÃO edite `game.gd` diretamente para adicionar features**
   - Use os módulos apropriados

2. **Classes de dados (data/maps/) são READONLY**
   - Nunca modifique em runtime
   - Apenas leia os dados

3. **Sempre use IsometricUtils para conversões**
   - Nunca calcule manualmente
   - Mantém consistência

4. **BattleManager é autônomo**
   - Comunica via signals
   - Não acesse internos dele diretamente

5. **MapRenderer não guarda estado**
   - Apenas desenha o que você passa
   - Estado fica em `game.gd`

---

**Dúvidas?** Consulte os comentários nos arquivos ou o README.md principal.
