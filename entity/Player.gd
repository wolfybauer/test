extends CharacterBody2D

enum DIR { SE, SW, NW, NE }
enum STATE { IDLE, JUMP}

var move_vector := Vector2.ZERO
var rest_pos = {}

@export var ACCELERATION = 600
@export var MAX_SPEED = 120
@export var FRICTION = 80
@export var PERF_MOVE = true

#var velocity = Vector2.ZERO

var fake_z = 0
var true_pos = Vector2.ZERO
var curr_tile = Vector2i.ZERO

var current_dir = DIR.SE
var current_state = STATE.IDLE
var prev_state = current_state
var updown:String = "_down"

@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite
@onready var collision_shape = $CollisionShape2D

func _ready():
	rest_pos['sprite'] = sprite.position.y
	rest_pos['collision_shape'] = collision_shape.position.y

func set_z(fz):
	if fz != fake_z:
		print('old z: ', fake_z, ' new z: ', fz)
		fake_z = fz
#		z_index = fz/8
#		if fz > fake_z:
#			z_index += (fz)
#		else:
#			z_index -= 1
#	print(true_pos - position)

	

func get_input():
	move_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	move_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	move_vector = move_vector.normalized()
	
	if PERF_MOVE:
		if move_vector.x > 0:
			move_vector.x = 1
		elif move_vector.x < 0:
			move_vector.x = -1
		if move_vector.y > 0:
			move_vector.y = 0.5
		elif move_vector.y < 0:
			move_vector.y= -0.5
	
func get_dir(vec_dir):
	if vec_dir.x < 0:
		if vec_dir.y < 0:
			updown = "_up"
			sprite.flip_h = true
			return DIR.NW
		else:
			updown = "_down"
			sprite.flip_h = true
			return DIR.SW
	else:
		if vec_dir.y < 0:
			updown = "_up"
			sprite.flip_h = false
			return DIR.NE
		else:
			updown = "_down"
			sprite.flip_h = false
			return DIR.SE

func move(delta):
	if move_vector:
		velocity = velocity.move_toward(move_vector * MAX_SPEED, ACCELERATION * delta)
		current_dir = get_dir(move_vector)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	if abs(velocity.x) > 10 or abs(velocity.y) > 10:
		anim_player.play("roll" + updown)
	else:
		anim_player.play("idle" + updown)

func jump(updown:String):
	anim_player.play("jump" + updown)

func jump_done():
	current_state = prev_state

func _physics_process(delta):
	sprite.position.y = rest_pos['sprite'] - fake_z
	collision_shape.position.y = rest_pos['collision_shape']- fake_z
	
#	sprite.position = true_pos
#	collision_shape.position = true_pos
	get_input()
	
	match current_state:
		STATE.IDLE:
			move(delta)
		STATE.JUMP:
			jump(updown)
	global_position.y = position.y
	move_and_slide()
	

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_accept"):
		prev_state = current_state
		current_state = STATE.JUMP
