extends NavdiSolePlayer

signal lasered(tile_affected_count : int)

var ate : bool = false
var atedur : int = 0
var vel : Vector2
@onready var spr = $SheetSprite
@onready var mover = $NavdiBodyMover
@onready var solidcast = $NavdiBodyMover/ShapeCast2D
enum { TURNBUF, TURNUPBUF, }
@onready var bufs = Bufs.Make(self).setup_bufons(
	[ TURNBUF, 4, TURNUPBUF, 4, ]
)

var lastcell : Vector2i
var casting : bool = false
var cast_cooldown : int = 0

var maze : Maze :
	get :
		return GameStage.current_stage.get_node("Maze")

func _physics_process(_delta: float) -> void:
	if ate:
		atedur += 1
		spr.setup([19])
		if atedur > 10 and Pin.get_action_hit():
			atedur = -100
			GameStage.current_stage.game_overed.emit(ERR_LINK_FAILED)
		return
		# ur ded
		
	var dpad : Vector2 = Pin.get_dpad() #as Vector2
	var actnow : bool = Pin.get_action_hit()
	var acting : bool = Pin.get_action_held()
	
	if actnow: casting = true
	if !acting: casting = false
	if casting: dpad *= 0
	$CPUParticles2D.emitting = casting
	if cast_cooldown > 0: cast_cooldown -= 1
	if casting and cast_cooldown <= 0 and maze:
		cast_cooldown = 20
		var cell : Vector2i = maze.local_to_map(position)
		var reveals : int = 0
		var flickers : int = 0
		for dx in [-1,0,1]:
			for dy in [-1,0,1]:
				if (dx==0)!=(dy==0):
					for i in range(1,40):
						var cell2 : Vector2i = cell+i*Vector2i(dx,dy)
						match maze.get_cell_tid(cell2):
							0, 40:
								reveal(cell2); reveals += 1;
							4,5,6, 44,45,46:
								flicker(cell2); flickers += 1;
							_:
								break
		if reveals > 0:
			lasered.emit(reveals)
		elif flickers > 0:
			lasered.emit(0)
	
	if maze:
		var cell : Vector2i = maze.local_to_map(position)
		#var celldata = maze.get_cell_tile_data(cell)
		#if celldata and get_collision_polygons_count(0)>0:
			#cell.y += 1
		if cell != lastcell:
			lastcell = cell
			if maze.get_cell_tid(cell) == 0:
				$blepmini.volume_db = -5
				$blepmini.pitch_scale = randf_range(0.8,1.2)
				$blepmini.play()
				flicker(cell)
			elif maze.get_cell_tid(cell) == 40:
				$blepmini.volume_db = -4
				$blepmini.pitch_scale = randf_range(1.2,1.6)
				$blepmini.play()
				flicker(cell)
			#maze.set_cell_tid(cell, 4)
		var tocenter : Vector2 = maze.map_to_center(cell) - position
		if casting:
			position.x += clamp(tocenter.x,-1,1)
			position.y += clamp(tocenter.y,-1,1)
		#if dpad.x == 0 and abs(tocenter.x) > 1: position.x += abs(vel.y) * sign(tocenter.x)
		#if dpad.y == 0 and abs(tocenter.y) > 1: position.y += abs(vel.x) * sign(tocenter.y)
		#if dpad.x == 0 and dpad.y == 0 and vel == Vector2.ZERO:
			#if abs(tocenter.x) > 1: dpad.x += 0.25 * sign(tocenter.x)
			#if abs(tocenter.y) > 1: dpad.y += 0.25 * sign(tocenter.y)
	
	var vel2 : Vector2 = dpad.normalized()
	if vel2.x != 0 and spr.flip_h != (vel2.x < 0):
		bufs.on(TURNUPBUF if dpad.y < 0 else TURNBUF)
		spr.flip_h = !spr.flip_h
	vel += (vel2-vel).limit_length(0.1)
	if vel.x and!mover.try_slip_move(self,solidcast,HORIZONTAL,vel.x):
		vel.x = 0
	if vel.y and!mover.try_slip_move(self,solidcast,VERTICAL,vel.y):
		vel.y = 0
	
	if casting: spr.setup([16,17,16,17,18,18,18,18,17,],5)
	elif bufs.has(TURNBUF): spr.setup([14])
	elif bufs.has(TURNUPBUF): spr.setup([15])
	elif dpad: spr.setup([13,12],8)
	else: spr.setup([12])

func flicker(targetcell:Vector2i) -> void:
	var plus : int = 0
	if maze.get_cell_tid(targetcell)>=40: plus = 40
	var maze = self.maze
	maze.set_cell_tid(targetcell,6+plus)
	await get_tree().create_timer(0.1*randf()).timeout
	if!is_instance_valid(maze): return
	maze.set_cell_tid(targetcell,4+plus)
func reveal(targetcell:Vector2i) -> void:
	var plus : int = 0
	if maze.get_cell_tid(targetcell)>=40: plus = 40
	var maze = self.maze
	maze.set_cell_tid(targetcell,6+plus)
	await get_tree().create_timer(0.1).timeout
	if!is_instance_valid(maze): return
	maze.set_cell_tid(targetcell,5+plus)
	await get_tree().create_timer(0.1).timeout
	if!is_instance_valid(maze): return
	maze.set_cell_tid(targetcell,4+plus)
func get_ate() -> void:
	if !ate:
		ate = true
		GameStage.current_stage.playerdead = true
	
