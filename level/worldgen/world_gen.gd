class_name WorldGen
extends Node

## Horizontal size of each chunk pillar in meters.
@export var chunk_size: int = 16
## How far from the player to keep chunks rendered, in meters.
@export var view_distance_m: float = 1000.0
## How far from the player to keep physics collision active, in meters.
@export var collision_distance_m: float = 96.0
@export var min_height: float = 2.0
@export var max_height: float = 40.0
@export var height_noise: FastNoiseLite
@export var chunk_material: Material

var chunk_pool: Array[Chunk] = []
var chunk_radius: int = 0
var collision_radius: int = 0
var _center_chunk: Vector2 = Vector2.ZERO
var _chunk_by_coord: Dictionary = {}


func _ready() -> void:
  if height_noise == null:
    height_noise = FastNoiseLite.new()
    height_noise.noise_type = FastNoiseLite.TYPE_PERLIN
    height_noise.seed = 42
    height_noise.frequency = 0.008
    height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    height_noise.fractal_octaves = 4

  if chunk_material == null:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.35, 0.55, 0.32)
    material.roughness = 0.9
    chunk_material = material

  set_view_distance(view_distance_m)
  collision_radius = maxi(1, ceili(collision_distance_m / float(chunk_size)))
  update_chunks(Vector2.ZERO)
  _place_player_on_terrain()


func _process(_delta: float) -> void:
  var player: CharacterBody3D = PlayerManager.player
  if player == null:
    return

  var new_coordinates := world_to_chunk_coordinates(player.position)
  if _center_chunk != new_coordinates:
    update_chunks(new_coordinates)


func set_view_distance(distance_m: float) -> void:
  view_distance_m = distance_m
  set_chunk_radius(maxi(1, ceili(distance_m / float(chunk_size))))


func set_chunk_radius(radius: int) -> void:
  chunk_radius = radius
  var pool_count := (2 * chunk_radius + 1) * (2 * chunk_radius + 1)

  if chunk_pool.size() > pool_count:
    for i in range(pool_count, chunk_pool.size()):
      var extra: Chunk = chunk_pool[i]
      _chunk_by_coord.erase(extra.coordinates)
      if extra.mesh_instance != null and is_instance_valid(extra.mesh_instance):
        extra.mesh_instance.queue_free()
    chunk_pool.resize(pool_count)

  chunk_pool.resize(pool_count)
  for i in range(pool_count):
    if chunk_pool[i] == null:
      chunk_pool[i] = Chunk.new(self)


func world_to_chunk_coordinates(world_coordinates: Vector3) -> Vector2:
  return Vector2(
    floorf(world_coordinates.x / float(chunk_size)),
    floorf(world_coordinates.z / float(chunk_size))
  )


func chunk_to_world_coordinates(chunk_coordinates: Vector2) -> Vector3:
  var half := float(chunk_size) * 0.5
  return Vector3(
    chunk_coordinates.x * chunk_size + half,
    0.0,
    chunk_coordinates.y * chunk_size + half
  )


func get_chunk_height(chunk_coordinates: Vector2) -> float:
  var world := chunk_to_world_coordinates(chunk_coordinates)
  var n := height_noise.get_noise_2d(world.x, world.z)
  return remap(n, -1.0, 1.0, min_height, max_height)


## Rebuild only chunks that entered/left the loaded ring.
func update_chunks(center_position: Vector2) -> void:
  var needed: Dictionary = {}
  for x in range(-chunk_radius, chunk_radius + 1):
    for y in range(-chunk_radius, chunk_radius + 1):
      needed[center_position + Vector2(x, y)] = true

  var recyclable: Array[Chunk] = []
  for chunk in chunk_pool:
    if chunk.loaded and needed.has(chunk.coordinates):
      needed.erase(chunk.coordinates)
    else:
      _chunk_by_coord.erase(chunk.coordinates)
      recyclable.append(chunk)

  _center_chunk = center_position

  for coord in needed.keys():
    var chunk: Chunk = recyclable.pop_back()
    chunk.rematerialize(coord)
    _chunk_by_coord[coord] = chunk

  _refresh_collision()


func _refresh_collision() -> void:
  for chunk in chunk_pool:
    if not chunk.loaded:
      continue
    var delta: Vector2 = chunk.coordinates - _center_chunk
    var in_range := absf(delta.x) <= collision_radius and absf(delta.y) <= collision_radius
    chunk.set_collision_enabled(in_range)


func get_chunk(chunk_coordinates: Vector2) -> Chunk:
  return _chunk_by_coord.get(chunk_coordinates)


func _place_player_on_terrain() -> void:
  var player: CharacterBody3D = PlayerManager.player
  if player == null:
    return
  var coords := world_to_chunk_coordinates(player.position)
  player.position.y = get_chunk_height(coords) + 1.5
