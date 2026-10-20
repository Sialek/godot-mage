class_name WorldGen
extends Node

var worldRoot : Node3D = Node3D.new()
var chunkPool : Array[Chunk] = []
var chunkRadius : int = 8
var chunkSize : int = 16
var _chunkDiameter : int = 2 * chunkRadius + 1
var _chunkPoolCount : int = pow(_chunkDiameter, 2)
var _centerChunk : Vector2 = Vector2.ZERO

@export var noiseTexture : NoiseTexture3D


func _ready() -> void:
  setChunkRadius(chunkRadius)
  reloadAllChunks(Vector2(0, 0))
  generate()


func _process(delta: float) -> void:
  var player : CharacterBody3D = PlayerManager.player
  if player:
    var newCoordinates = worldToChunkCoordinates(player.position)
    if _centerChunk != newCoordinates:
      reloadAllChunks(newCoordinates)


func generate() -> void:
  pass


func setChunkRadius(radius: int) -> void:
  chunkRadius = radius
  _chunkDiameter = 2 * chunkRadius + 1
  _chunkPoolCount = pow(_chunkDiameter, 2)
  chunkPool.resize(_chunkPoolCount)
  for x in range(_chunkDiameter):
    for y in range (_chunkDiameter):
      if not chunkPool[x * _chunkDiameter + y]:
        chunkPool[x * _chunkDiameter + y] = Chunk.new(self, Vector2(0, 0))
    
func worldToChunkCoordinates(worldCoordinates: Vector3) -> Vector2:
  return floor(Vector2(worldCoordinates.x, worldCoordinates.z) / chunkSize)

func chunkToWorldCoordinates(chunkCoordinates: Vector2) -> Vector3:
  return Vector3(chunkCoordinates.x, 0, chunkCoordinates.y) * chunkSize

func reloadAllChunks(centerPosition: Vector2):
  _centerChunk = centerPosition
  _chunkDiameter = 2 * chunkRadius + 1
  var coordinateStack = []
  for x in range(_chunkDiameter):
    for y in range (_chunkDiameter):
      coordinateStack.push_back(Vector2(centerPosition.x + x - chunkRadius, centerPosition.y + y - chunkRadius))
  for chunk in chunkPool:
    chunk.unload()
    chunk.coordinates = coordinateStack.pop_back()
    chunk.load()

func unloadChunk(chunkCoordinates: Vector2) -> void:
  getChunk(chunkCoordinates).unload()
  
func loadChunk(chunkCoordinates: Vector2) -> void:
  getChunk(chunkCoordinates).load()

func getChunk(chunkCoordinates: Vector2) -> Chunk:
  var local_x = floor(chunkCoordinates.x - _centerChunk.x + chunkRadius)
  var local_y = floor(chunkCoordinates.y - _centerChunk.y + chunkRadius)
  return chunkPool[local_x * _chunkDiameter + local_y]
