extends TileMapLayer

@export var tile_size: Vector2 = Vector2(16, 16)

const CrumbleTile = preload("res://Prefabs/crumbling_plattform.tscn")

func _ready():
	convert_all_tiles()

func convert_all_tiles():
	var all_tiles = get_used_cells()
	for tile_pos in all_tiles:
		spawn_static_tile(tile_pos)
	clear()

func spawn_static_tile(tile_pos: Vector2i):
	# get tile texture info
	var source_id = get_cell_source_id(tile_pos)
	var atlas_coords = get_cell_atlas_coords(tile_pos)
	var source = tile_set.get_source(source_id) as TileSetAtlasSource
	var texture = source.texture
	var region = source.get_tile_texture_region(atlas_coords, 0)
	
	# get world position
	var world_pos = to_global(map_to_local(tile_pos))
	
	# instantiate prefab
	var body = CrumbleTile.instantiate()
	body.add_to_group("crumble_tile") 
	get_parent().add_child.call_deferred(body)
	body.global_position = world_pos
	
	# set the texture on the Sprite2D child
	var sprite = body.get_node("Sprite2D")
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
