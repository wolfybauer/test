extends StaticBody2D

class_name SwayObj

var fake_z = 0
var tile_size
@export var random_flip_h = true
@export var max_skew = -0.1
@export var skew_duration = 8.0

@onready var inert_sprite = $InertSprite
@onready var sway_sprite = $SwaySprite
@onready var tex:Texture2D = $InertSprite.texture
@onready var collision_shape = $CollisionShape2D
@onready var shadow = $LightOccluder2D

func _ready():
#	sprite.texture = tex
#	sprite.hframes = h_frames
	var rand_hframe = randi() % inert_sprite.hframes
	inert_sprite.frame = rand_hframe
	sway_sprite.frame = rand_hframe
	if random_flip_h:
		var rand_flip = randi() % 2
		inert_sprite.flip_h = rand_flip
		sway_sprite.flip_h = rand_flip
	
	var tw = create_tween()
	tw.tween_interval(randf_range(6.0, 8.0))
	tw.set_loops()
	tw.tween_property(sway_sprite, 'skew', max_skew, skew_duration)
	tw.tween_property(sway_sprite, 'skew', 0.05, skew_duration)

func set_z(new_z:int):
	fake_z = new_z
	inert_sprite.offset.y -= new_z
	sway_sprite.offset.y -= new_z
	collision_shape.position.y -= new_z
	shadow.position.y -= new_z

func tile_sz():
	# how many actual tiles does it take up
	var tile_x = (tex.get_width() / 32) / inert_sprite.hframes
	var tile_y = (tex.get_height() / 16)
	tile_size = Vector2i(tile_x, tile_y)
	return tile_size
