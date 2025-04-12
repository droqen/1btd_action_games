extends Label

func _ready() -> void:
	get_parent().lasered.connect(func(tct):show())
