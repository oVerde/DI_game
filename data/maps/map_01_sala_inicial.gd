extends Resource
class_name MapData01

## Mapa 1: Sala Inicial
## Primeiro mapa do jogo - sala de tutorial

static func get_data() -> Dictionary:
	return {
		"name": "Sala Inicial",
		"size": Vector2(15, 10),
		"player_spawn": Vector2(2, 5),
		"walls": [
			# Parede superior
			Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0),
			Vector2(5, 0), Vector2(6, 0), Vector2(7, 0), Vector2(8, 0), Vector2(9, 0),
			Vector2(10, 0), Vector2(11, 0), Vector2(12, 0), Vector2(13, 0), Vector2(14, 0),
			
			# Parede inferior
			Vector2(0, 9), Vector2(1, 9), Vector2(2, 9), Vector2(3, 9), Vector2(4, 9),
			Vector2(5, 9), Vector2(6, 9), Vector2(7, 9), Vector2(8, 9), Vector2(9, 9),
			Vector2(10, 9), Vector2(11, 9), Vector2(12, 9), Vector2(13, 9), Vector2(14, 9),
			
			# Parede esquerda
			Vector2(0, 1), Vector2(0, 2), Vector2(0, 3), Vector2(0, 4), Vector2(0, 5),
			Vector2(0, 6), Vector2(0, 7), Vector2(0, 8),
			
			# Parede direita (exceto porta)
			Vector2(14, 1), Vector2(14, 2), Vector2(14, 3), Vector2(14, 4),
			Vector2(14, 6), Vector2(14, 7), Vector2(14, 8)
		],
		"doors": [
			# Porta para o Corredor (Mapa 2)
			{
				"pos": Vector2(14, 5),
				"leads_to": 1  # Índice do Mapa 2 no array de mapas
			}
		],
		"enemies": []  # Sem inimigos neste mapa
	}
