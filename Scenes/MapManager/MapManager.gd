### ----------------------------------------------------
### Decides what chunks of the map are meant to be simulated in the game
### ----------------------------------------------------

extends Node2D

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

const SIM_RANGE = 1

# All GameEntities that need to be simulated 
# for an example enemy following the player (so it doesnt get unloaded)
var SimulatedEntities := Array() # [ GameEntity,... ]

# Focus of both camera and rendering tilemap 
var GameFocusEntity:GameEntity

# List of chunks loaded
var LoadedChunks:Array = [] # [ Vector3, ... ]

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

# Starts and initializes a given game save
func start_simulation(SaveName:String, MapName:String) -> bool:
	if(not SaveManager.load_sav(SaveName, MapName, $TileMapManager.TileMaps)):
		Logger.logErr(["Failed to load save: ", SaveName, " ", MapName], get_stack())
		return false
	
	var Player := SaveManager.get_PlayerEntity()
	$EntityManager.load_player(Player)
	GameFocusEntity = Player

	update_simulation()
	return true

# Ran every single tick
func update_simulation() -> void:
	update_map(get_chunks_to_load(),
		LibK.Vectors.vec3_get_pos_in_chunk(GameFocusEntity.MapPosition, SIM_RANGE))

# Gets chunks that need to be loaded to the map depending on SimulatedEntities
func get_chunks_to_load() -> Array:
	var ChunksToLoad := []
	for entity in SimulatedEntities:
		var sqrRange := LibK.Vectors.vec3_get_square(entity.MapPosition, SIM_RANGE, false)
		for chunkV3 in sqrRange:
			if ChunksToLoad.has(chunkV3): continue
			ChunksToLoad.append(chunkV3)
	return ChunksToLoad

# Updates the whole game map based on data from save
func update_map(ChunksToLoad:Array, ChunksToRender:Array) -> void:
	# Loading chunks that are not yet rendered
	for chunkV3 in ChunksToLoad:
		if LoadedChunks.has(chunkV3): continue
		var DataDict := SaveManager.get_TileData_on_chunk(chunkV3, DATA.TILEMAPS.CHUNK_SIZE)
		
		# If chunks in range of focus object load them to TileMaps
		if(ChunksToRender.has(chunkV3)):
			$TileMapManager.load_chunk_to_tilemap(chunkV3, DataDict)
		LoadedChunks.append(chunkV3)
	
	# Unload old chunks that are not in range (iterate backwards)
	for i in range(LoadedChunks.size() - 1, -1, -1):
		var chunkV3:Vector3 = LoadedChunks[i]
		if ChunksToLoad.has(chunkV3): continue
		
		# If chunks in range of focus object unload them from TileMaps
		if(ChunksToRender.has(chunkV3)):
			$TileMapManager.unload_chunk_from_tilemap(chunkV3)
		LoadedChunks.remove(i)
	
	$TileMapManager.update_all_TM_bitmask()
