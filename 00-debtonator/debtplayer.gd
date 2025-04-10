extends NavdiSolePlayer

var vel : Vector2
@onready var spr = $SheetSprite
@onready var mover = $NavdiBodyMover
@onready var solidcast = $NavdiBodyMover/ShapeCast2D
enum { TURNBUF, TURNUPBUF, WANDING_BUF, }
@onready var bufs = Bufs.Make(self).setup_bufons(
	[ TURNBUF, 4, TURNUPBUF, 4, WANDING_BUF, 10 ]
)

func _physics_process(_delta: float) -> void:
	var dpad : Vector2 = Pin.get_dpad() #as Vector2
	var actnow : bool = Pin.get_action_hit()
	if bufs.has(WANDING_BUF):
		dpad *= 0
	
	var vel2 : Vector2 = dpad.normalized()
	if vel2.x != 0 and spr.flip_h != (vel2.x < 0):
		bufs.on(TURNUPBUF if dpad.y < 0 else TURNBUF)
		spr.flip_h = !spr.flip_h
		$mid.scale.x = -1 if spr.flip_h else 1
	vel += (vel2-vel).limit_length(0.1)
	if vel.x and!mover.try_slip_move(self,solidcast,HORIZONTAL,vel.x):
		vel.x = 0
	if vel.y and!mover.try_slip_move(self,solidcast,VERTICAL,vel.y):
		vel.y = 0
	if actnow:
		bufs.on(WANDING_BUF)
	
	if bufs.has(WANDING_BUF):
		$mid.show()
	else:
		$mid.hide()
	
	if bufs.has(WANDING_BUF): spr.setup([16])
	elif bufs.has(TURNBUF): spr.setup([14])
	elif bufs.has(TURNUPBUF): spr.setup([15])
	elif dpad: spr.setup([13,12],8)
	else: spr.setup([12])
	
