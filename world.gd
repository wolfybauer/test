extends Node2D

@export var RANDOMIZE = true

var tile_scale:Vector2i
var MAX_HEIGHT = 4 # zero indexed, temporary. aka terrain map atlas coords max x

@onready var tmap:TileMap = $TerrainMap
@onready var rmap:TileMap = $ReplacerMap

@onready var alt_sprite:Sprite2D = $AltitudeNoise
@onready var temp_sprite:Sprite2D = $TemperatureNoise
@onready var moist_sprite:Sprite2D = $MoistureNoise
@onready var alt_noise:FastNoiseLite = $AltitudeNoise.texture.noise
@onready var temp_noise:FastNoiseLite = $TemperatureNoise.texture.noise
@onready var moist_noise:FastNoiseLite = $MoistureNoise.texture.noise

const tile_type = {
	'water' : 0,
	'sand' : 1,
	'drygrass' : 2,
	'wetgrass' : 3,
	'dirt' : 4,
	'snow' : 5
}

const HEIGHT_TO_ATLAS = {
	0 : 0,
	1 : 1,
	2 : 3,
	3 : 5,
	4 : 9,
}

func how_high(alt):
	var inc = 1.0 / float(MAX_HEIGHT + 1)
	for h in range(1,MAX_HEIGHT+1):
		var lo = (h - 1) * inc
		var hi = h * inc
		if alt >= lo and alt < hi:
			return h - 1
	return MAX_HEIGHT

# Called when the node enters the scene tree for the first time.
func _ready():
	# make the noise sprites invisible
	alt_sprite.visible = false
	temp_sprite.visible = false
	moist_sprite.visible = false
	
	# set noise seeds if random
	if RANDOMIZE:
		randomize()
		alt_noise.seed = randi()
		temp_noise.seed = randi()
		moist_noise.seed = randi()
	
	print('tmap size: ', tmap.tile_set.tile_size)
	print('rmap size: ', rmap.tile_set.tile_size)
	tile_scale = rmap.tile_set.tile_size / tmap.tile_set.tile_size
	print('scale: ', tile_scale)
	print('half: ', tile_scale / 2)
	print(alt_noise.get_noise_2d(3000,3000))
#	print(tn.get_noise_2d(10, 10))
	replace()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
#	mouse_pos = to_local(get_global_mouse_position())
#	var tmap_pos = tmap.local_to_map(mouse_pos)
#	var td = tmap.get_cell_tile_data(0, tmap_pos)
#	if td:
#		print(td.get_custom_data('floor'))
	pass

func replace():
	for rcel in rmap.get_used_cells(0):
		# get top left corner of replacer cell
		var start_pos = tmap.local_to_map(rmap.map_to_local(rcel)) - tile_scale/2
		# loop thru terrain cells in replacer cell
		for x in range(tile_scale.x):
			for y in range(tile_scale.y):
				var pos = start_pos + Vector2i(x,y)
				# only set if no tile yet present at coords in terrain tilemap
				if tmap.get_cell_source_id(0, pos) == -1:
					# get the noise
					var anoise = 2 * (abs(alt_noise.get_noise_2d(pos.x, pos.y)))
					var tnoise = 2 * (abs(temp_noise.get_noise_2d(pos.x, pos.y)))
					var mnoise = 2 * (abs(moist_noise.get_noise_2d(pos.x, pos.y)))
					var ay = HEIGHT_TO_ATLAS[how_high(anoise)]
					tmap.set_cell(0, pos, 1, Vector2i(1,ay))
					print(ay)
					pass
