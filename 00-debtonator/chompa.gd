extends Node2D

var maze : Maze
var astar : AStar2D
var player : NavdiSolePlayer

var vel : Vector2
@onready var spr : SheetSprite = $SheetSprite
@onready var mover : NavdiBodyMover = $NavdiBodyMover
@onready var solidcast : ShapeCast2D = $NavdiBodyMover/ShapeCast2D

var angry : int = 0
var stunned : int = 0

func _ready() -> void:
	spr.flip_h = true # face left by default ofc

func _physics_process(_delta: float) -> void:
	if maze == null:
		if GameStage.current_stage:
			maze = GameStage.current_stage.get_node("Maze")
			astar = maze.astar([0,4,5,6,2,3])
		else:
			return
	elif player == null:
		if NavdiSolePlayer.GetPlayer(self).vel != Vector2.ZERO:
			player = NavdiSolePlayer.GetPlayer(self)
		spr.setup([20])
	else:
		var cell = maze.local_to_map(position)
		if maze.get_cell_tid(cell) == 5: stunned = 100; angry = 0;
		if stunned > 0:
			stunned -= 1
			if stunned < 25:
				spr.setup([20,22],5)
			else:
				spr.setup([23,22],7)
		else:
			if vel.x and!mover.try_slip_move(self,solidcast,HORIZONTAL,vel.x):
				vel.x = 0
			if vel.y and!mover.try_slip_move(self,solidcast,VERTICAL,vel.y):
				vel.y = 0
			if vel:
				spr.setup([21,20],8)
			else:
				if spr.frame == 21:
					pass
				else:
					spr.setup([20])
				
			var pcell = maze.local_to_map(player.position)
			var p1 = astar.get_closest_point(cell)
			var p2 = astar.get_closest_point(pcell)
			var path = astar.get_point_path(p1,p2)
			var cell2 : Vector2 = cell
			if path and len(path)>1:
				cell2 = path[1]
			if cell.x!=cell2.x: spr.flip_h = cell2.x<cell.x
			var tocell : Vector2 = maze.map_to_center(cell) - position
			var tocell2 : Vector2 = maze.map_to_center(cell2) - position
			var targetvel : Vector2
			var movespeed : float = remap(angry,0.0,100.0,0.55,1.15)
			if !$playerlooker.is_colliding():
				if angry < 100: angry += 30
				else: angry = 100
				targetvel = $playerlooker.target_position.limit_length(movespeed)
			else:
				if player.vel == Vector2.ZERO:
					movespeed -= 0.55
				
				if angry > 0: angry -= 2
				else: angry = 0
				if (cell.x!=cell2.x and cell.y!=cell2.y) or abs(tocell2.x) <3 or abs(tocell2.y) <3:
					targetvel = tocell2.limit_length(movespeed)
				else:
					targetvel = tocell.limit_length(movespeed)
			$playerlooker.target_position = player.position - position
			$playerlooker.force_shapecast_update()
			vel += (targetvel-vel).limit_length(0.15) # accel
			
			if $playerlooker.target_position.length() < 8:
				position += 0.5 * (player.position - position)
				player.get_ate()
