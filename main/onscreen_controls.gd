extends Control

func _physics_process(_delta: float) -> void:
	size = get_viewport().size
	print(size,get_viewport().size)
