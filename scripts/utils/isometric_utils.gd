extends Node
class_name IsometricUtils

## Utilitários para conversão de coordenadas isométricas
## Conversão entre coordenadas cartesianas (grid) e isométricas (tela)

# Constantes de tamanho dos tiles
const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const TILE_WIDTH_HALF := TILE_WIDTH / 2
const TILE_HEIGHT_HALF := TILE_HEIGHT / 2

## Converte coordenadas cartesianas (grid) para isométricas (tela)
## @param cart: Coordenadas cartesianas (x, y) da grade
## @return: Coordenadas isométricas (x, y) da tela
static func cartesian_to_isometric(cart: Vector2) -> Vector2:
	return Vector2(
		(cart.x - cart.y) * TILE_WIDTH_HALF,
		(cart.x + cart.y) * TILE_HEIGHT_HALF
	)

## Converte coordenadas isométricas (tela) para cartesianas (grid)
## @param iso: Coordenadas isométricas (x, y) da tela
## @return: Coordenadas cartesianas (x, y) da grade
static func isometric_to_cartesian(iso: Vector2) -> Vector2:
	return Vector2(
		(iso.x / TILE_WIDTH_HALF + iso.y / TILE_HEIGHT_HALF) / 2,
		(iso.y / TILE_HEIGHT_HALF - iso.x / TILE_WIDTH_HALF) / 2
	)

## Converte input do jogador (WASD) para movimento na grade isométrica
## @param input: Vetor de input (-1, 0, 1) em cada eixo
## @return: Vetor de movimento na grade
static func input_to_isometric_movement(input: Vector2) -> Vector2:
	var move_vector := Vector2.ZERO
	# W/S controla Y, A/D controla X
	# Transformação para movimento isométrico
	move_vector.x = input.x + input.y
	move_vector.y = input.y - input.x
	return move_vector.normalized() if move_vector.length() > 0 else Vector2.ZERO

## Calcula profundidade (depth) para sorting de renderização
## @param pos: Posição cartesiana na grade
## @return: Valor de profundidade (quanto maior, mais atrás)
static func calculate_depth(pos: Vector2) -> float:
	return pos.x + pos.y

## Verifica se uma posição está dentro dos limites do mapa
## @param pos: Posição a verificar
## @param map_size: Tamanho do mapa (width, height)
## @return: true se a posição é válida
static func is_position_valid(pos: Vector2, map_size: Vector2) -> bool:
	return pos.x >= 0 and pos.x < map_size.x and pos.y >= 0 and pos.y < map_size.y
