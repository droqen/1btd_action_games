extends Node2D

@export var stages : Array[PackedScene]
@export var stage_index : int = 3
@export var game_holder : Node2D
@export var camera : Camera2D
var stage : GameStage
var loop : AudioStreamPlayer :
	get : 
		match stage_index:
			4,5,6: return $loop2
			_: return $loop

var goingtostage : GameStage
var goingprogress : float = -1.0
enum { GOING_DEATH, GOING_ANGELS, }
var goingtype = GOING_ANGELS;
var laseblur : float
var _laseblur : float
var gamerunning : bool = false

func _ready() -> void:
	set_stage(stages[stage_index].instantiate())
	get_viewport().size_changed.connect(update_stage_size)
	PokiSDK.commercial_break_done.connect(self._on_commercial_break_done)

func _physics_process(delta: float) -> void:
	if GameStage.current_stage and GameStage.current_stage.gamerunning and not GameStage.current_stage.playerdead:
		loop.pitch_scale = move_toward(loop.pitch_scale,1.0,delta)
		loop.volume_db = move_toward(loop.volume_db,0.0,delta)
	if goingtostage != null:
		match goingtype:
			GOING_ANGELS:
				if goingprogress < 0: goingprogress += delta
				goingprogress += delta * 0.25
			GOING_DEATH:
				goingprogress += delta * 2.0
		if goingprogress > 1:
			goingprogress = -1
			set_stage(goingtostage)
			goingtostage = null
		update_blur()
	elif goingprogress < 0:
		goingprogress += delta * 0.5
		if goingprogress >= 0: goingprogress = 0
		update_blur()
	
	if _laseblur!=laseblur:
		_laseblur = move_toward(lerp(_laseblur,laseblur,0.5),laseblur,delta)
		update_blur()
	if GameStage.current_stage.playerdead:
		if loop.playing and not goingtostage:
			loop.stop()
			$dead.volume_db = loop.volume_db
			$dead.play()
	elif laseblur > 0:
		laseblur -= 3.0 * delta
		if loop.playing:
			loop.play(loop.get_playback_position()-delta)

func update_blur() -> void:
	var whiteout = pow(abs(goingprogress),4)
	var blur_strength = abs(goingprogress)*15.0+0.5 + _laseblur*5.0*randf()
	(material as ShaderMaterial).set_shader_parameter("whiteout",whiteout)
	(material as ShaderMaterial).set_shader_parameter("strength",blur_strength)

func update_stage_size() -> void:
	var vpsize = get_viewport().size
	var maxscale = min(vpsize.x / (stage.width+10), vpsize.y / (stage.height+10))
	if maxscale < 1: maxscale = 1
	camera.position = game_holder.position + Vector2(stage.width/2,stage.height/2)
	camera.zoom = Vector2(maxscale, maxscale)

func set_stage(stage : GameStage) -> void:
	if !loop.playing:
		loop.play()
		loop.pitch_scale = 0.5
		loop.volume_db = -10
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
	GameStage.current_stage.lasered.connect(_on_stage_lasered)
	GameStage.current_stage.game_overed.connect(_on_stage_game_overed)
	update_stage_size()
	
	process_mode = Node.PROCESS_MODE_DISABLED
	PokiSDK.commercialBreak()

func _on_commercial_break_done(response) -> void:
	print("commercial done", response)
	process_mode = Node.PROCESS_MODE_INHERIT
	PokiSDK.gameplayStart()

func _on_stage_game_overed(gostate) -> void:
	if loop.playing:
		loop.stop()
		print("game over @",gostate)
		PokiSDK.gameplayStop()
	match gostate:
		ERR_LINK_FAILED:
			loop.play()
			loop.pitch_scale = 0.5
			loop.volume_db = -10
			NavdiSolePlayer.GetPlayer(self).name = "dead"
			goingtostage = stages[stage_index].instantiate()
			goingtype = GOING_DEATH;
		ERR_CANT_ACQUIRE_RESOURCE:
			if NavdiSolePlayer.GetPlayer(self).name != "winner winner chicken player":
				$win.play()
				NavdiSolePlayer.GetPlayer(self).name = "winner winner chicken player"
				stage_index += 1
				goingtostage = stages[stage_index].instantiate()
				goingtype = GOING_ANGELS;

func _on_stage_lasered(affected_tile_count) -> void:
	if affected_tile_count == 0:
		laseblur = 0.25
		$blep.volume_db = -10
		$blep.pitch_scale = randf_range(1.2,1.4)
	else:
		laseblur = 1.0
		$blep.volume_db = 0
		$blep.pitch_scale = randf_range(1.8,2.5)
	if loop == $loop2:
		$blep.pitch_scale *= 0.5
	$blep.play()
	
