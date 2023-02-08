extends Node2D

@export var RANDOMIZE = true
@export var FAKE_Z = true

var tile_scale:Vector2i
var MAX_HEIGHT = 4 # zero indexed, temporary. aka terrain map atlas coords max x

# hold biome data for each tile
var biome_map = {}
var objects_map = {}

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
	'plains' : { 'palm' : 0.01, 'derrick' : 0.01 },
	'beach' : { 'rock' : 0.001 },
	'jungle' : { 'tree' : 0.015 },
	'desert' : { 'rock' : 0.003, 'cacti' : 0.02, 'palm' : 0.001 },
	'highlands' : { 'tree' : 0.01, 'derrick' : 0.005 },
	'mountain' : { 'rock' : 0.001, 'derrick' : 0.001 },
	'water' : {}
}

var rand_obj = {
	'cacti' : preload("res://terrain_objects/cacti.tscn"),
	'tree' : preload("res://terrain_objects/tree.tscn"),
	'palm' : preload("res://terrain_objects/palm.tscn"),
	'rock' : preload("res://terrain_objects/rock.tscn"),
	'derrick' : preload("res://terrain_objects/derrick.tscn")
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
func get_terrain_z(tmap_pos):
	var td = tmap.get_cell_tile_data(0, tmap_pos)
	if td: return td.get_custom_data('floor')
	else: return 0
	

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
	set_objects()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	if FAKE_Z:
		if player.velocity:
			var tp = tmap.local_to_map(player.position)
			player.set_z(get_terrain_z(tp))

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
					var ay:int
					if FAKE_Z:
						ay = HEIGHT_TO_ATLAS[how_high(anoise)]
					else:
						ay = HEIGHT_TO_ATLAS[0]
					var ax = tile_type[get_tile(anoise, tnoise, mnoise)]
					biome_map[pos] = get_biome(anoise, tnoise, mnoise)
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
			

func get_biome(alt, temp, moist):
	# sea level
	if alt < LOWLAND_START:
		return 'water'
	# lowlands
	elif in_range(alt, LOWLAND_START, MIDLAND_START):
		return 'beach'
	# inland
	elif in_range(alt, MIDLAND_START, HIGHLAND_START):
		
		if temp < HIGH_TEMP:
			# low moisture
			if moist < MID_HUMID:
				return 'desert'
			# normal moisture
			elif in_range(moist, MID_HUMID, HIGH_HUMID):
				return 'plains'
			# high moisture
			else:
				return 'jungle'
		else:
			if moist < HIGH_HUMID:
				return 'desert'
			else:
				return 'jungle'
	# highlands
	elif in_range(alt, HIGHLAND_START, MOUNTAIN_START):
		if moist < MID_HUMID:
			return 'highlands'
		else:
			return 'jungle'
	# mountains
	else:
		return 'mountain'

func set_objects():
	for pos in biome_map:
		var curr_biome = biome_map[pos]
		var obj = rand_in_biome(object_data, curr_biome)
		if obj != null:
			objects_map[pos] = obj
			tile_to_scene(obj, pos)
#		print(biome)

func rand_in_biome(data_in, biome_in):
	var current_biome = data_in[biome_in]
	var rn = randf_range(0,1)
	var running_total = 0
	for tile in current_biome:
		running_total = running_total + current_biome[tile]
		if rn <= running_total:
			return tile

func tile_to_scene(obj, pos):
	var inst = rand_obj[str(obj)].instantiate()
	add_child(inst)
	
	inst.position = tmap.map_to_local(pos) #+ Vector2i(16, 8)
	var sz = inst.tile_sz()
	
	if FAKE_Z:
		inst.set_z(get_terrain_z(pos))
	var surrounding = tmap.get_surrounding_cells(pos)
	for s_pos in surrounding:
		# cull if terrain around not even + fake z enabled
		if FAKE_Z and not (get_terrain_z(s_pos) == inst.fake_z):
			print('terain not even! deleting obj at:', pos)
			inst.queue_free()
		# cull if too close to another object
		else:
			if s_pos in objects_map:
				print('too close! deleting obj at:', pos, '| sz:', sz)
				inst.queue_free()
					
