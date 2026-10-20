class_name Chunk
extends RefCounted

var coordinates: Vector2 = Vector2.ZERO
var loaded: bool = false
var mesh_instance: MeshInstance3D
var _box_mesh: BoxMesh
var _body: StaticBody3D
var _collision_shape: CollisionShape3D
var _box_shape: BoxShape3D
var world_gen: WorldGen


func _init(owner_world_gen: WorldGen, chunk_coordinates: Vector2 = Vector2.ZERO) -> void:
  world_gen = owner_world_gen
  coordinates = chunk_coordinates


func ensure_ready() -> void:
  if mesh_instance != null:
    return

  _box_mesh = BoxMesh.new()
  mesh_instance = MeshInstance3D.new()
  mesh_instance.mesh = _box_mesh
  if world_gen.chunk_material:
    mesh_instance.material_override = world_gen.chunk_material
  world_gen.add_child(mesh_instance)


func rematerialize(chunk_coordinates: Vector2) -> void:
  ensure_ready()
  coordinates = chunk_coordinates

  var size := float(world_gen.chunk_size)
  var height := world_gen.get_chunk_height(coordinates)
  var half := size * 0.5
  var dimensions := Vector3(size, height, size)

  _box_mesh.size = dimensions
  if _box_shape != null:
    _box_shape.size = dimensions

  mesh_instance.position = Vector3(
    coordinates.x * size + half,
    height * 0.5,
    coordinates.y * size + half
  )
  mesh_instance.visible = true
  loaded = true


func set_collision_enabled(enabled: bool) -> void:
  if enabled:
    _ensure_collision()
  elif _body != null and is_instance_valid(_body):
    _body.queue_free()
    _body = null
    _collision_shape = null
    _box_shape = null


func _ensure_collision() -> void:
  if mesh_instance == null:
    return
  if _body != null and is_instance_valid(_body):
    return

  _box_shape = BoxShape3D.new()
  _box_shape.size = _box_mesh.size

  _collision_shape = CollisionShape3D.new()
  _collision_shape.shape = _box_shape

  _body = StaticBody3D.new()
  _body.add_child(_collision_shape)
  mesh_instance.add_child(_body)


func deactivate() -> void:
  if mesh_instance != null:
    mesh_instance.visible = false
  set_collision_enabled(false)
  loaded = false
