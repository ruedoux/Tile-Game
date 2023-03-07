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

# List of chunks loaded from save
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
	SimulatedEntities.append(Player)
	update_simulation()
	return true

# Ran every single tick
# If reload is true: 
# Clears loaded chunks and loads everything again (refreshes changes to save on loaded chunks)
func update_simulation(reload:bool=false) -> void:
	update_map(get_chunks_to_load(), reload)

# Updates the whole game map based on data from save
# reload clears loaded chunks and loads everything again (refreshes changes to save on loaded chunks)
func update_map(ChunksToLoad:Dictionary, reload:bool=false) -> void:
	if(reload): LoadedChunks.clear()
	# Loading chunks that are not yet rendered
	for chunkV3 in ChunksToLoad:
		if LoadedChunks.has(chunkV3): continue
		var DataDict := SaveManager.get_TileData_on_chunk(chunkV3, GLOBAL.TILEMAPS.CHUNK_SIZE)

		# If chunks in range of focus object load them to TileMaps
		if(ChunksToLoad[chunkV3]):
			$TileMapManager.load_chunk_to_tilemap(chunkV3, DataDict)
		$EntityManager.load_entities_on_chunk(chunkV3, DataDict)
		LoadedChunks.append(chunkV3)
	
	# Unload old chunks that are not in range (iterate backwards)
	for i in range(LoadedChunks.size() - 1, -1, -1):
		var chunkV3:Vector3 = LoadedChunks[i]
		if ChunksToLoad.has(chunkV3): continue
		
		# If chunks in range of focus object unload them from TileMaps
		if(ChunksToLoad[chunkV3]):
			$TileMapManager.unload_chunk_from_tilemap(chunkV3)
		$EntityManager.unload_entities_on_chunk(chunkV3)
		LoadedChunks.remove(i)
	
	$TileMapManager.update_all_TM_bitmask()

# Gets chunks that need to be loaded to the map depending on SimulatedEntities
func get_chunks_to_load() -> Dictionary:
	var ChunksToLoad := {} # { Vector3:renderBool }
	for entity in SimulatedEntities:
		var sqrRange := LibK.Vectors.vec3_get_range_2d(entity.MapPosition, SIM_RANGE)
		if entity is PlayerEntity:
			for chunkV3 in sqrRange:
				ChunksToLoad[chunkV3] = true
			continue
		for chunkV3 in sqrRange:
			ChunksToLoad[chunkV3] = false
	return ChunksToLoad
