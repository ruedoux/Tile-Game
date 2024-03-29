### ----------------------------------------------------
### Container for all TileMaps
### Takes care of showing the map to the player
### ----------------------------------------------------

extends Node2D

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

# Reference to all tilemaps
var TileMaps := Array()

# Keeps track of rendered chunks
var RenderedChunks := Array()

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

# Setups all TileMaps from TileMap dir and adds them as children
func _enter_tree() -> void:
	for packed in LibK.Files.get_file_list_at_dir(GLOBAL.TILEMAPS.TILEMAPS_DIR):
		var filePath:String = packed[0]
		var fileName:String = packed[1]
		var TMScene:PackedScene = load(filePath + "/" + fileName + ".tscn")
		var TMInstance = TMScene.instance()
		add_child(TMInstance)
	TileMaps = get_tilemaps()

# Updates bitmask of all TileMaps
func update_all_TM_bitmask() -> void:
	for tileMap in TileMaps: tileMap.update_bitmask_region()

# Loads a singular chunk to TileMaps
# Optimized for MapManager (Doesnt directly ask save for data)
func load_chunk_to_tilemap(chunkV3:Vector3, DataDict:Dictionary) -> void:
	for tileMap in TileMaps:
		var TMName = tileMap.get_name()
		for posV3 in DataDict:
			tileMap.set_cellv(LibK.Vectors.vec3_vec2(posV3), DataDict[posV3].get_from_IDDict(TMName))
	RenderedChunks.append(chunkV3)
	update_all_TM_bitmask()
	
# Loads tiles from every TileMap on position, return false if tile not in loaded chunks
func refresh_tile_on(posV3:Vector3, tileData:TileData) -> bool:
	var chunkV3:Vector3 = LibK.Vectors.scale_down_vec3(posV3, GLOBAL.TILEMAPS.CHUNK_SIZE)
	if(not RenderedChunks.has(chunkV3)):
		Logger.logErr(["Tried to refresh tile on unloaded chunk: ", chunkV3, ", pos: ", posV3], get_stack())
		return false
	
	for tileMap in TileMaps:
		var TMName = tileMap.get_name()
		tileMap.set_cellv(
			LibK.Vectors.vec3_vec2(posV3),
			tileData.get_from_IDDict(TMName))

	update_all_TM_bitmask()
	return true

# Unloads a single chunk from TileMaps
func unload_chunk_from_tilemap(chunkV3:Vector3) -> void:
	for posV3 in LibK.Vectors.vec3_get_pos_in_chunk(chunkV3, GLOBAL.TILEMAPS.CHUNK_SIZE):
		for tileMap in TileMaps:
			tileMap.set_cellv(LibK.Vectors.vec3_vec2(posV3), -1)
	RenderedChunks.erase(chunkV3)
	update_all_TM_bitmask()

func unload_all_chunks() -> void:
	# Iterate backwards to safely erase entries
	for i in range(RenderedChunks.size() - 1, -1, -1):
		unload_chunk_from_tilemap(RenderedChunks[i])
	update_all_TM_bitmask()

# Returns all TileMaps that are children of this node
func get_tilemaps() -> Array:
	var TM:Array = []
	for node in get_children(): if node is TileMap: TM.append(node)
	return TM
