extends Node

@export var maze : Maze 
#@export var angel : Node2D
@export var enemies : Node
var angels : Array[Node2D]
var gameover : bool = false
var gameover_dur : int = 0

const ANGEL_PREFAB = preload("res://00-debtonator/angel.tscn")

func _physics_process(_delta: float) -> void:
	if gameover:
		for angel in angels:
			angel.position.y -= 0.3
		gameover_dur += 1
		if gameover_dur > 0:
			get_parent().game_overed.emit(ERR_CANT_ACQUIRE_RESOURCE)
			gameover_dur = -100 # just to avoid rebounce
	elif!maze.get_used_cells_by_tids([0,40]):
		gameover = true
		NavdiSolePlayer.GetPlayer(self).process_mode = Node.PROCESS_MODE_DISABLED # paused.
		for enemy in enemies.get_children():
			enemy.queue_free()
			var angel = ANGEL_PREFAB.instantiate()
			angel.position = enemy.position
			angels.append(angel)
			enemies.add_child(angel)
	
		
