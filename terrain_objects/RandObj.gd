extends StaticBody2D

class_name RandObj

var fake_z = 0
var tile_size
@export var random_flip_h = true

#@export var tex:Texture2D
#@export var h_frames:int = 1

@onready var sprite = $Sprite
@onready var tex:Texture2D = $Sprite.texture
@onready var collision_shape = $CollisionShape2D
@onready var shadow = $LightOccluder2D

func _ready():
#	sprite.texture = tex
#	sprite.hframes = h_frames
	sprite.frame = randi() % sprite.hframes
	if random_flip_h:
		sprite.flip_h = randi() % 2

func set_z(new_z:int):
	fake_z = new_z
	sprite.offset.y -= new_z
	collision_shape.position.y -= new_z
	shadow.position.y -= new_z

func tile_sz():
	# how many actual tiles does it take up
	var tile_x = (tex.get_width() / 32) / sprite.hframes
	var tile_y = (tex.get_height() / 16)
	tile_size = Vector2i(tile_x, tile_y)
	return tile_size
