@tool
extends Node2D
class_name GameStage
static var current_stage : GameStage

signal game_overed(gostate)
signal lasered(tct)

var gamerunning : bool = false
var playerdead : bool = false

func _ready() -> void:
	await get_tree().physics_frame
	NavdiSolePlayer.GetPlayer(self).lasered.connect(func(tct):lasered.emit(tct))

@export var width : int = 100
@export var height : int = 100
@export var border_colour : Color = Color(1,0,1,1)
func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(0,0,width,height), border_colour, false)
		draw_rect(Rect2(0-2,0-2,width+4,height+4), border_colour, false)
