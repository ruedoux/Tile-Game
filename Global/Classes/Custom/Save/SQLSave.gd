### ----------------------------------------------------
# Manages SQLite
#
# Data is saved to chunks of size MAPDATA_CHUNK_SIZE which are compressed
# Data is loaded whenever data from a given chunk is requested
# This system will not work well if data is requested from multiple chunks alternately
# because it would cause the system to load and unload the same data from sql db
#
# To setup a save use create_new_save() and initialize()
# To load save use only initialize()
#
# Before saving use save_to_sqlDB() to unload all data from cache (MapData variable)
#
### ----------------------------------------------------

extends "res://Global/Classes/Custom/Save/SQLSaveBase.gd"
class_name SQLSave

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

# List of loaded chunks from sql to cache variables with their access counter
# Counter from every chunk is subtracted every time data is loaded
# This allows to unload long not accessed chunk
var SQLLoadedChunks := Dictionary() # {ChunkPos:accessCounter, ...}

# Cache of all loaded data from sql
# Holds map data (not meant to be editet directly!)
# { PackedPos:TileData }
var MapData := Dictionary()

# Holds TileSet data
var TS_CONTROL := Dictionary() # { TSName:{tileID:tileName} }

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func _init(fileName:String, fileDir:String, verbose = false).(fileName, fileDir, verbose) -> void:
	#Logger.logMS(["Created new SQLSave Object: ", FILE_DIR, " ", FILE_NAME])
	pass

# Should be called after init before trying to acess data from save
# Loads all metadata to cache variables, copies save to temp
func initialize() -> bool:
	if(not LibK.Files.file_exist(DEST_PATH)):
		Logger.logErr(["Unable to initialize save, file doesnt exist: ", DEST_PATH], get_stack())
		return false
	
	var result := LibK.Files.copy_file(DEST_PATH, SQL_DB_GLOBAL.path)
	if(not result == OK):
		Logger.logErr(["Failed to copy db from temp to save: ", DEST_PATH, " -> ", SQL_DB_GLOBAL.path], get_stack())
		return false
	
	# Initialize TS_CONTROL
	var tempArr = str2var(sql_load_compressed(TABLE_NAMES.keys()[TABLE_NAMES.METADATA_TABLE], "TS_CONTROL"))
	if(not tempArr is Dictionary):
		Logger.logErr(["Failed do initialize TS_CONTROL from SQL save, str2var is not Dictionary: ", SQL_DB_GLOBAL.path], get_stack())
		return false
	
	TS_CONTROL = tempArr

	if(beVerbose): Logger.logMS(["Initialized save: ", DEST_PATH, " -> ", SQL_DB_GLOBAL.path])
	return true
	
# If save already exists, create a new one and put old one in the trash
func create_new_save(TileMaps:Array) -> bool:
	if(LibK.Files.file_exist(DEST_PATH)):
		if(OS.move_to_trash(ProjectSettings.globalize_path(DEST_PATH)) != OK):
			Logger.logErr(["Unable to delete save file: ", DEST_PATH], get_stack())
			return false

	var result := LibK.Files.create_empty_file(DEST_PATH)
	if(result != OK):
		Logger.logErr(["Unable to create empty save file: ", DEST_PATH, ", err: ", result], get_stack())
		return false
	
	SQL_DB_GLOBAL.path = DEST_PATH
	var isOK := true
	for TID in TABLE_NAMES.values():
		var tableName:String = TABLE_NAMES.keys()[TID]
		isOK = isOK and add_table(tableName, TABLE_CONTENT)
	isOK = isOK and fill_METADATA_TABLE(TileMaps)
	SQL_DB_GLOBAL.path = FILE_DIR + FILE_NAME +"_TEMP.db"
	
	if(not isOK):
		Logger.logErr(["Failed to create tables: ", DEST_PATH], get_stack())
		return isOK
	Logger.logMS(["Created DataBase at: ", DEST_PATH])
	return isOK

# Check if the current tilemaps are compatible with TS_CONTROL tilemaps
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
func save_to_sqlDB(savePath:String = "") -> bool:
	if(savePath == ""): savePath = DEST_PATH
	if(LibK.Files.file_exist(savePath)):
		if(OS.move_to_trash(ProjectSettings.globalize_path(savePath)) != OK):
			Logger.logErr(["Unable to delete save file: ", savePath], get_stack())
			return false
	
	for chunkV3 in SQLLoadedChunks.keys():
		_unload_SQLChunk(chunkV3)
	do_query("VACUUM;") # Vacuum save to reduce its size

	var result := LibK.Files.copy_file(SQL_DB_GLOBAL.path, savePath)
	if(not result == OK):
		Logger.logErr(["Failed to copy db from temp to save: ", SQL_DB_GLOBAL.path, " -> ", savePath, ", result: ", result], get_stack())
		return false
	
	Logger.logMS(["Saved SQLSave: ", savePath])
	return true

### ----------------------------------------------------
# Map - Set / Get / Remove Tile
### ----------------------------------------------------


# Sets TileData on a given position (with compatibility check, not meant for bulk)
func set_TileData_on(posV3:Vector3, tileData:TileData) -> bool:
	if(not tileData.check_IDDict_compatible(TS_CONTROL)): return false
	_update_SQLLoadedChunks(LibK.Vectors.scale_down_vec3(posV3, MAPDATA_CHUNK_SIZE))
	MapData[posV3] = str(tileData)
	return true

# Removes TileData on a position permamently
# Retruns true if data was erased
func remove_TileData_on(posV3:Vector3) -> bool:
	return MapData.erase(posV3)

# Adds tile to TileData on a given position (with compatibility check, not meant for bulk)
func add_tile_to_TileData_on(posV3:Vector3, TSName:String, tileID:int) -> bool:
	if(not TS_CONTROL.has(TSName)): return false
	if(not TS_CONTROL[TSName].has(tileID)): return false
	# Get via function to avoid tying to add tile to not existing TileData entry in MapData
	var editedTD := get_TileData_on(posV3)
	editedTD.add_to_IDDict(TSName, tileID)
	MapData[posV3] = str(editedTD)
	return true

# Removes TSName from TileData IDDict
# Returns false when data was not erased
func remove_tile_from_TileData(TSName:String, posV3:Vector3) -> bool:
	var editedTD := get_TileData_on(posV3)
	if(editedTD.IDDict.empty()): return false
	var erased := editedTD.erase_from_IDDict(TSName)
	MapData[posV3] = str(editedTD)
	return erased

# Adds entity data on a given position
func add_Entity_to_TileData(posV3:Vector3, entity:GameEntity) -> bool:
	# Get via function to avoid tying to add tile to not existing TileData entry in MapData
	var editedTD := get_TileData_on(posV3)
	editedTD.EntityData = str(entity)
	MapData[posV3] = str(editedTD)
	return true

# Removes EntytyData from TileData on given position
# Returns true if EntityData was erased
func remove_Entity_from_TileData(posV3:Vector3) -> bool:
	var editedTD := get_TileData_on(posV3)
	if(editedTD.EntityData.empty()): return false
	editedTD.EntityData = ""
	MapData[posV3] = str(editedTD)
	return true

# Returns tile on a given position (with compatibility check, not meant for bulk)
# Returns a new empty tiledata on fail
func get_TileData_on(posV3:Vector3) -> TileData:
	_update_SQLLoadedChunks(LibK.Vectors.scale_down_vec3(posV3, MAPDATA_CHUNK_SIZE))
	if(not MapData.has(posV3)): return TileData.new()
	return TileData.new().from_str(MapData[posV3])

# Get positions in chunk, better optimized for getting a lot of data (no check for every tile)
func get_TileData_on_chunk(chunkPosV3:Vector3, chunkSize:int) -> Dictionary:
	if(not MAPDATA_CHUNK_SIZE%chunkSize == 0):
		Logger.logErr(["MAPDATA_CHUNK_SIZE%chunkSize must be 0: ",chunkSize, " ", MAPDATA_CHUNK_SIZE], get_stack())
		return {}
	if(chunkSize>MAPDATA_CHUNK_SIZE):
		Logger.logErr(["chunkSize should be lower or equal to MAPDATA_CHUNK_SIZE: ",chunkSize, " ", MAPDATA_CHUNK_SIZE], get_stack())
		return {}
	
	var resultDict := {}
	_update_SQLLoadedChunks(LibK.Vectors.scale_down_vec3(chunkPosV3, MAPDATA_CHUNK_SIZE/chunkSize))
	for posV3 in LibK.Vectors.vec3_get_pos_in_chunk(chunkPosV3,chunkSize):
		if(not MapData.has(posV3)): 
			resultDict[posV3] = TileData.new()
			continue
		resultDict[posV3] = TileData.new().from_str(MapData[posV3])
	return resultDict

### ----------------------------------------------------
# Data from sql management
### ----------------------------------------------------


# Load data from SQLChunk to MapData
func _load_SQLChunk(SQLChunkPos:Vector3) -> void:
	var converted = str2var(sql_load_compressed(TABLE_NAMES.keys()[TABLE_NAMES.MAPDATA_TABLE], SQLChunkPos))
	
	# Merge data for every stored MapData key
	if(converted is Dictionary):
		MapData.merge(converted)	
	elif(not converted is String): 
		Logger.logErr(["Converted loaded sql chunk is not a Dictionary or String! Pos: ", SQLChunkPos], get_stack())
	
	# Set countdown at max
	SQLLoadedChunks[SQLChunkPos] = SQL_CT_UNLOAD_NUM

	# Unload old chunks that were not used for a long time to save RAM
	for chunkV3 in SQLLoadedChunks.keys():
		SQLLoadedChunks[chunkV3] -= 1
		if(SQLLoadedChunks[chunkV3] == 0):
			_unload_SQLChunk(chunkV3)

# Load data from MapData to SQLChunk
func _unload_SQLChunk(SQLChunkPos:Vector3) -> void:
	var PosToUnload := LibK.Vectors.vec3_get_pos_in_chunk(SQLChunkPos, MAPDATA_CHUNK_SIZE)
	var DictToSave := {}
	
	for posV3 in PosToUnload:
		if(not MapData.has(posV3)): continue
		DictToSave[posV3] = MapData[posV3]
		MapData.erase(posV3)
	
	sql_save_compressed(var2str(DictToSave), TABLE_NAMES.keys()[TABLE_NAMES.MAPDATA_TABLE], SQLChunkPos)
	
	# Get rid of entry fully
	SQLLoadedChunks.erase(SQLChunkPos)

# Loads requested data from sql database
# If data is being read from tiles close this should not cause much of performance drag
func _update_SQLLoadedChunks(SQLChunkPos:Vector3) -> void:
	if(SQLLoadedChunks.has(SQLChunkPos)): return # Chunk already loaded from sql
	_load_SQLChunk(SQLChunkPos)
