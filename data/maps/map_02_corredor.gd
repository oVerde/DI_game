extends Resource
class_name MapData02

## Mapa 2: Corredor
## Área de transição entre a Sala Inicial e a Sala do Chefe

static func get_data() -> Dictionary:
	return {
		"name": "Corredor",
		"size": Vector2(20, 10),
		"player_spawn": Vector2(2, 5),
		"walls": [
			# Parede superior
			Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0),
			Vector2(5, 0), Vector2(6, 0), Vector2(7, 0), Vector2(8, 0), Vector2(9, 0),
			Vector2(10, 0), Vector2(11, 0), Vector2(12, 0), Vector2(13, 0), Vector2(14, 0),
			Vector2(15, 0), Vector2(16, 0), Vector2(17, 0), Vector2(18, 0), Vector2(19, 0),
			
			# Parede inferior
			Vector2(0, 9), Vector2(1, 9), Vector2(2, 9), Vector2(3, 9), Vector2(4, 9),
			Vector2(5, 9), Vector2(6, 9), Vector2(7, 9), Vector2(8, 9), Vector2(9, 9),
			Vector2(10, 9), Vector2(11, 9), Vector2(12, 9), Vector2(13, 9), Vector2(14, 9),
			Vector2(15, 9), Vector2(16, 9), Vector2(17, 9), Vector2(18, 9), Vector2(19, 9),
			
			# Parede esquerda (exceto porta de volta)
			Vector2(0, 1), Vector2(0, 2), Vector2(0, 3), Vector2(0, 4),
			Vector2(0, 6), Vector2(0, 7), Vector2(0, 8),
			
			# Parede direita (exceto porta para Sala do Chefe)
			Vector2(19, 1), Vector2(19, 2), Vector2(19, 3), Vector2(19, 4),
			Vector2(19, 6), Vector2(19, 7), Vector2(19, 8)
		],
		"doors": [
			# Porta de volta para Sala Inicial (Mapa 1)
			{
				"pos": Vector2(0, 5),
				"leads_to": 0
			},
			# Porta para Sala do Chefe (Mapa 3)
			{
				"pos": Vector2(19, 5),
				"leads_to": 2
			}
		],
		"enemies": []  # Sem inimigos neste mapa
	}
