extends Resource
class_name MapData03

## Mapa 3: Sala do Chefe
## Sala final com inimigo Slime

static func get_data() -> Dictionary:
	return {
		"name": "Sala do Chefe",
		"size": Vector2(15, 12),
		"player_spawn": Vector2(2, 6),
		"walls": [
			# Parede superior
			Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0),
			Vector2(5, 0), Vector2(6, 0), Vector2(7, 0), Vector2(8, 0), Vector2(9, 0),
			Vector2(10, 0), Vector2(11, 0), Vector2(12, 0), Vector2(13, 0), Vector2(14, 0),
			
			# Parede inferior
			Vector2(0, 11), Vector2(1, 11), Vector2(2, 11), Vector2(3, 11), Vector2(4, 11),
			Vector2(5, 11), Vector2(6, 11), Vector2(7, 11), Vector2(8, 11), Vector2(9, 11),
			Vector2(10, 11), Vector2(11, 11), Vector2(12, 11), Vector2(13, 11), Vector2(14, 11),
			
			# Parede esquerda (exceto porta de volta)
			Vector2(0, 1), Vector2(0, 2), Vector2(0, 3), Vector2(0, 4), Vector2(0, 5),
			Vector2(0, 7), Vector2(0, 8), Vector2(0, 9), Vector2(0, 10),
			
			# Parede direita
			Vector2(14, 1), Vector2(14, 2), Vector2(14, 3), Vector2(14, 4), Vector2(14, 5),
			Vector2(14, 6), Vector2(14, 7), Vector2(14, 8), Vector2(14, 9), Vector2(14, 10)
		],
		"doors": [
			# Porta de volta para Corredor (Mapa 2)
			{
				"pos": Vector2(0, 6),
				"leads_to": 1
			}
		],
		"enemies": [
			# Slime - inimigo principal do mapa
			{
				"pos": Vector2(10, 6),
				"name": "Slime",
				"hp": 30,
				"attack": 5
			}
		]
	}
