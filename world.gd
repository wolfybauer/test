extends Node2D

@export var RANDOMIZE = true

var tile_scale:Vector2i
var MAX_HEIGHT = 4 # zero indexed, temporary. aka terrain map atlas coords max x

# altitude seperators
@export var LOWLAND_START := 0.045
@export var MIDLAND_START := 0.2
@export var HIGHLAND_START := 0.8
@export var MOUNTAIN_START := 0.95

# temp seperators
@export var MID_TEMP := 0.2
@export var HIGH_TEMP := 0.9

# humidity
@export var MID_HUMID := 0.3
@export var HIGH_HUMID := 0.6

@onready var tmap:TileMap = $TerrainMap
@onready var rmap:TileMap = $ReplacerMap

@onready var alt_noise:FastNoiseLite = $NoiseMaps/AltitudeNoise.texture.noise
@onready var temp_noise:FastNoiseLite = $NoiseMaps/TemperatureNoise.texture.noise
@onready var moist_noise:FastNoiseLite = $NoiseMaps/MoistureNoise.texture.noise

#@onready var player = $TerrainMap/Player
@onready var player = $Player

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

const biome_data = {
	'plains' : { 'drygrass' : 1.0 },
	'beach' : { 'sand' : 1.0, 'dirt' : 0.0 },
	'jungle' : { 'wetgrass' : 1.0 },
	'desert' : { 'sand' : 0.8, 'dirt' : 0.2 },
	'highlands' : { 'dirt' : 0.95, 'water' : 0.05 },
	'mountain' : { 'dirt' : 0.95, 'snow' : 0.05 },
	'water' : { 'water' : 1.0 }
}

const object_data = {
	'plains' : { 'palm' : 0.005 },
	'beach' : { 'rock' : 0.0005 },
	'jungle' : { 'tree' : 0.01 },
	'desert' : { 'rock' : 0.003, 'cacti' : 0.01, 'palm' : 0.0005 },
	'highlands' : { 'tree' : 0.01 },
	'mountain' : { 'rock' : 0.001},
	'water' : {}
}

# utility
func in_range(val, lo, hi):
	return val >= lo and val < hi
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
	$NoiseMaps.visible = false
	
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
	if player.velocity:
		var tmap_pos = tmap.local_to_map(player.position)
		var td = tmap.get_cell_tile_data(0, tmap_pos)
		if td:
			player.fake_z = td.get_custom_data('floor')

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
					var ax = tile_type[get_tile(anoise, tnoise, mnoise)]
					tmap.set_cell(0, pos, 1, Vector2i(ax,ay))
					pass

func get_tile(alt, temp, moist):
	# sea level
	if alt < LOWLAND_START:
		return 'water'
	# lowlands
	elif in_range(alt, LOWLAND_START, MIDLAND_START):
#		return 'beach'
		return 'sand'
	# inland
	elif in_range(alt, MIDLAND_START, HIGHLAND_START):
		
		if temp < HIGH_TEMP:
			# low moisture
			if moist < MID_HUMID:
#				return 'desert'
				return 'sand'
			# normal moisture
			elif in_range(moist, MID_HUMID, HIGH_HUMID):
				return 'drygrass'
			# high moisture
			else:
				return 'wetgrass'
		else:
			if moist < HIGH_HUMID:
				return 'sand'
			else:
				return 'wetgrass'
	# highlands
	elif in_range(alt, HIGHLAND_START, MOUNTAIN_START):
#		return 'highlands'
		if moist < MID_HUMID:
			return 'dirt'
		else:
			return 'wetgrass'
	# mountains
	else:
		if moist > MID_HUMID:
			return 'snow'
		else:
			return 'dirt'
			
