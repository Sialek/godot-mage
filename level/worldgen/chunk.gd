class_name Chunk
extends Node

var coordinates : Vector2
var size : int = 16
var loaded : bool = false
var mesh : MeshInstance3D
var worldGen : WorldGen

func _init(ownerWorldGen: WorldGen, chunkCoordinates: Vector2):
  worldGen = ownerWorldGen
  coordinates = chunkCoordinates


func _ready() -> void:
  pass


func _process(delta: float) -> void:
  pass


func load() -> void:
  if not loaded:
    mesh = MeshInstance3D.new()
    var boxMesh = BoxMesh.new()
    boxMesh.size = Vector3(15.0, 1.0, 15.0)
    mesh.position = worldGen.chunkToWorldCoordinates(coordinates)
    mesh.mesh = boxMesh
    mesh.create_trimesh_collision()
    worldGen.add_child(mesh)
    loaded = true


func unload() -> void:
  if loaded:
    if is_instance_valid(mesh):
      mesh.queue_free()
    mesh = null
    loaded = false
