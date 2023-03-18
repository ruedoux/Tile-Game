### ----------------------------------------------------
# Manages SQLite
#
# Data is saved to chunks of size SQL_CHUNK_SIZE which are compressed
# Data is loaded whenever data from a given chunk is requested
# This system will not work well if data is requested from multiple chunks alternately
# because it would cause the system to load and unload the same data from sql db
#
# To setup a save use create_new_save() and initialize()
# To load save use only initialize()
#
# Before saving use save_to_sqlDB() to unload all data from cache (MapDataCache variable)
#
### ----------------------------------------------------

extends "res://Global/Classes/Custom/Save/SQLSaveBase.gd"
class_name SQLSave

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

# Unload chunk if data wasnt requested for 128 updates (max loaded chunks number)
const SQL_CT_UNLOAD_NUM = 128 

# List of loaded chunks from sql to cache variables with their access counter
# Counter from every chunk is subtracted every time data is loaded
# This allows to unload long not accessed chunk
var SQLLoadedChunks := Dictionary() # {ChunkPos:accessCounter, ...}

# Cache of all loaded data from sql
# Holds map data (not meant to be editet directly!)
var MapDataCache := MapData.new()

# Holds TileSet data
var TS_CONTROL := Dictionary() # { TSName:{tileID:tileName} }

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func _init(fileName:String, fileDir:String, verbose = false) -> void:
	_setupDB(fileName, fileDir, verbose)

# Should be called after init before trying to acess data from save
func load(TileMaps:Array) -> bool:
	isReadyNoErr = false
	SQL_DB_GLOBAL.path = DEST_PATH

	if(not LibK.Files.file_exist(DEST_PATH)):
		Logger.logErr(["Tried to init non existing save: ", DEST_PATH], get_stack())
		return isReadyNoErr
	
	TS_CONTROL = _get_dict_from_table(
		TABLE_NAMES.keys()[TABLE_NAMES.GAMEDATA_TABLE],
		GAMEDATA_KEYS.keys()[GAMEDATA_KEYS.TS_CONTROL])
	
	if(TS_CONTROL.empty()):
		Logger.logErr(["Failed do initialize TS_CONTROL from SQL save, TS_CONTROL is empty: ", DEST_PATH], get_stack())
		return isReadyNoErr

	if(not check_compatible(TileMaps)): 
		return isReadyNoErr
	
	if(LibK.Files.copy_file(DEST_PATH, TEMP_PATH) != OK):
		Logger.logErr(["Failed to copy db from dest to temp: ", DEST_PATH, " -> ", TEMP_PATH], get_stack())
		return isReadyNoErr
	
	SQL_DB_GLOBAL.path = TEMP_PATH
	isReadyNoErr = true
	Logger.logMS(["Loaded SQLSave: ", DEST_PATH])
	return isReadyNoErr

# Check if tilemaps are compatible with TS_CONTROL tilemaps
func check_compatible(TileMaps:Array) -> bool:
	var isOK := true
	for tileMap in TileMaps:
		var TSName:String = tileMap.get_name()
		var tileSet:TileSet = tileMap.tile_set
		
		if not TS_CONTROL.has(TSName):
			Logger.logErr(["TS_CONTROL is missing TSName: " + TSName], get_stack())
			isOK = false
			continue
		
		var tileNamesIDs = LibK.TS.get_tile_names_and_IDs(tileSet)
		for index in range(tileNamesIDs.size()):
			var tileName:String = tileNamesIDs[index][0]
			var tileID:int = tileNamesIDs[index][1]
			if not TS_CONTROL[TSName].has(tileID):
				Logger.logErr(["TS_CONTROL is missing tileID: ", tileID], get_stack())
				isOK = false
				continue
			
			if TS_CONTROL[TSName][tileID] != tileName:
				Logger.logErr(["TileName doesn't match for tileID: ", tileID, " | ", tileName, " != ", TS_CONTROL[TSName][tileID]],
					get_stack())
				isOK = false
				continue
	return isOK

# Save everything, leave savePath empty if you want to overwrite save
func save(savePath:String = "") -> bool:
	if(savePath == ""): savePath = DEST_PATH
	if(LibK.Files.file_exist(savePath)):
		if(OS.move_to_trash(ProjectSettings.globalize_path(savePath)) != OK):
			Logger.logErr(["Unable to delete save file: ", savePath], get_stack())
			return false
	
	for chunk in MapDataCache.Data.keys():
		_unload_SQLChunk(chunk)
	
	var result := LibK.Files.copy_file(TEMP_PATH, savePath)
	if(not result == OK):
		Logger.logErr(["Failed to copy db from temp to save: ", TEMP_PATH, " -> ", savePath, ", result: ", result], get_stack())
		return false
	
	SQL_DB_GLOBAL.path = savePath
	do_query("VACUUM;") # Vacuum save to reduce its size
	SQL_DB_GLOBAL.path = TEMP_PATH
	Logger.logMS(["Saved SQLSave: ", savePath])
	return true

### ----------------------------------------------------
# GameData control
### ----------------------------------------------------

# Returns saved player data from save
func get_PlayerEntity() -> PlayerEntity:
	var PlayerEntityStr = _sql_load_compressed(
		TABLE_NAMES.keys()[TABLE_NAMES.GAMEDATA_TABLE],
		GAMEDATA_KEYS.keys()[GAMEDATA_KEYS.PLAYER_DATA])
	return PlayerEntity.new().from_str(PlayerEntityStr)

# Saves Player Entity
func set_PlayerEntity(Player:PlayerEntity) -> bool:
	_sql_save_compressed(
		Player.to_string(),
		TABLE_NAMES.keys()[TABLE_NAMES.GAMEDATA_TABLE],
		GAMEDATA_KEYS.keys()[GAMEDATA_KEYS.PLAYER_DATA])
	return true

### ----------------------------------------------------
# MapDataCache control
### ----------------------------------------------------

# Sets TileData on a given position (with compatibility check, not meant for bulk)
func set_TileData_on(posV3:Vector3, tileData:TileData) -> bool:
	if(not tileData.check_IDDict_compatible(TS_CONTROL)): return false
	_update_SQLLoadedChunks(pos_to_SQLChunk(posV3))
	MapDataCache.set_in_Data(pos_to_SQLChunk(posV3), posV3, tileData)
	return true

# Returns tile on a given position (with compatibility check, not meant for bulk)
# Returns a new empty tiledata on fail
func get_TileData_on(posV3:Vector3) -> TileData:
	_update_SQLLoadedChunks(pos_to_SQLChunk(posV3))
	return MapDataCache.get_in_Data(pos_to_SQLChunk(posV3), posV3)

# Removes TileData on a position permamently
# Retruns true if data was erased
func remove_TileData_on(posV3:Vector3) -> bool:
	return MapDataCache.rem_in_Data(pos_to_SQLChunk(posV3), posV3)

# Adds tile to TileData on a given position (with compatibility check, not meant for bulk)
func add_tile_to_TileData_on(posV3:Vector3, TSName:String, tileID:int) -> bool:
	if(not TS_CONTROL.has(TSName)): 
		return false
	if(not TS_CONTROL[TSName].has(tileID)): 
		return false
	var editedTD := get_TileData_on(posV3)
	editedTD.add_to_IDDict(TSName, tileID)
	MapDataCache.set_in_Data(pos_to_SQLChunk(posV3), posV3, editedTD)
	return true

# Removes TSName from TileData IDDict
# Returns false when data was not erased
func remove_tile_from_TileData(TSName:String, posV3:Vector3) -> bool:
	var editedTD := get_TileData_on(posV3)
	var erased := editedTD.erase_from_IDDict(TSName)
	MapDataCache.set_in_Data(pos_to_SQLChunk(posV3), posV3, editedTD)
	return erased

# Adds entity data on a given position
func add_Entity_to_TileData(posV3:Vector3, entity:GameEntity) -> void:
	var editedTD := get_TileData_on(posV3)
	editedTD.EntityData = str(entity)
	MapDataCache.set_in_Data(pos_to_SQLChunk(posV3), posV3, editedTD)

# Removes EntytyData from TileData on given position
# Returns true if EntityData was erased
func remove_Entity_from_TileData(posV3:Vector3) -> void:
	var editedTD := get_TileData_on(posV3)
	editedTD.EntityData = ""
	MapDataCache.set_in_Data(pos_to_SQLChunk(posV3), posV3, editedTD)

# Get positions in one z level chunk, better optimized for getting a lot of data (no check for every tile)
func get_TileData_on_chunk(chunkPosV3:Vector3, chunkSize:int) -> Dictionary:
	if(not SQL_CHUNK_SIZE%chunkSize == 0):
		Logger.logErr(["SQL_CHUNK_SIZE%chunkSize must be 0: ",chunkSize, " ", SQL_CHUNK_SIZE], get_stack())
		return {}
	if(chunkSize>SQL_CHUNK_SIZE):
		Logger.logErr(["chunkSize should be lower or equal to SQL_CHUNK_SIZE: ",chunkSize, " ", SQL_CHUNK_SIZE], get_stack())
		return {}
	
	var ChunkPos := LibK.Vectors.vec3_vec2(LibK.Vectors.scale_down_vec3(chunkPosV3, SQL_CHUNK_SIZE/chunkSize))
	_update_SQLLoadedChunks(ChunkPos)

	var returnDict := {}
	if(not MapDataCache.Data.has(ChunkPos)):
		return returnDict

	var DictRef:Dictionary = MapDataCache.Data[ChunkPos]
	for posV3 in LibK.Vectors.vec3_get_pos_in_chunk(chunkPosV3, chunkSize):
		if(not DictRef.has(posV3)):
			continue
		returnDict[posV3] = TileData.new().from_str(DictRef[posV3])
	return returnDict

### ----------------------------------------------------
# Chunk Data System Management
### ----------------------------------------------------

# Load data from SQLChunk to MapDataCache
func _load_SQLChunk(ChunkPos:Vector2) -> void:
	var converted = str2var(_sql_load_compressed(TABLE_NAMES.keys()[TABLE_NAMES.MAPDATA_TABLE], ChunkPos))
	
	# Merge data for every stored MapDataCache key
	if(converted is Dictionary):
		MapDataCache.set_in_Data_chunk(ChunkPos, converted)
	elif(not converted is String):
		Logger.logErr(["Converted loaded sql chunk is not a Dictionary or String! Pos: ", ChunkPos], get_stack())
	
	# Set countdown at max
	SQLLoadedChunks[ChunkPos] = SQL_CT_UNLOAD_NUM
	if(beVerbose): Logger.logMS(["Loaded SQLChunk: ", ChunkPos])

	# Unload old chunks that were not used for a long time
	for chunk in SQLLoadedChunks.keys():
		SQLLoadedChunks[chunk] -= 1
		if(SQLLoadedChunks[chunk] == 0):
			_unload_SQLChunk(chunk)

# Take data from MapDataCache and save it to SQLChunk
func _unload_SQLChunk(ChunkPos:Vector2) -> void:
	var DictToSave := MapDataCache.get_in_Data_chunk(ChunkPos)
	MapDataCache.rem_in_Data_chunk(ChunkPos)
	
	_sql_save_compressed(var2str(DictToSave), TABLE_NAMES.keys()[TABLE_NAMES.MAPDATA_TABLE], ChunkPos)
	SQLLoadedChunks.erase(ChunkPos)
	if(beVerbose): Logger.logMS(["Unloaded SQLChunk: ", ChunkPos])
	
# Loads requested data from sql database
# If data is being read from tiles close this should not cause much of performance drag
func _update_SQLLoadedChunks(ChunkPos:Vector2) -> void:
	if(SQLLoadedChunks.has(ChunkPos)): return # Chunk already loaded from sql
	_load_SQLChunk(ChunkPos)
