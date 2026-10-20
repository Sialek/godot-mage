extends Node3D


func _ready() -> void:
  pass # Replace with function body.


func _process(delta: float) -> void:
  pass

func _unhandled_input(event: InputEvent) -> void:
  if Input.is_action_just_pressed("quit"):
    get_tree().quit()
