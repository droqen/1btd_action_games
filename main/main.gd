extends Node2D

@export var first_stage : PackedScene
@export var next_stage : PackedScene
@export var game_holder : Node2D
@export var camera : Camera2D
var stage : GameStage

func _ready() -> void:
	set_stage(first_stage.instantiate())
	get_viewport().size_changed.connect(update_stage_size)

func update_stage_size() -> void:
	var vpsize = get_viewport().size
	var maxscale = min(vpsize.x / (stage.width+10), vpsize.y / (stage.height+10))
	if maxscale < 1: maxscale = 1
	camera.position = game_holder.position + Vector2(stage.width/2,stage.height/2)
	camera.zoom = Vector2(maxscale, maxscale)

func set_stage(stage : GameStage) -> void:
	var already_stage : bool = false
	for child in game_holder.get_children():
		if child == stage:
			already_stage = true; continue;
		else:
			child.queue_free()
	if !already_stage:
		game_holder.add_child(stage)
		stage.owner = owner if owner else self
	self.stage = stage
	if GameStage.current_stage:
		GameStage.current_stage.game_overed.disconnect(_on_stage_game_overed)
	GameStage.current_stage = stage
	GameStage.current_stage.game_overed.connect(_on_stage_game_overed)
	update_stage_size()

func _on_stage_game_overed(gostate) -> void:
	print("game over @",gostate)
	match gostate:
		ERR_LINK_FAILED:
			NavdiSolePlayer.GetPlayer(self).name = "dead"
			set_stage(first_stage.instantiate())
		ERR_CANT_ACQUIRE_RESOURCE:
			NavdiSolePlayer.GetPlayer(self).name = "winner winner chicken player"
			set_stage(next_stage.instantiate())
