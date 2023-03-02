### ----------------------------------------------------
### Singleton handles all save management
### ----------------------------------------------------

extends Node

### ----------------------------------------------------
### VARIABLES
### ----------------------------------------------------

const MAP_FOLDER := "res://Resources/SavedMaps/"
const SAV_FOLDER := "res://Resources/SavedSaves/"

var _CurrentMap:SQLSave = null
var _CurrentSav:SQLSave = null

### ----------------------------------------------------
### FUNCTIONS
### ----------------------------------------------------

# Destructor, cleans TEMP files on game close
func _notification(what:int) -> void:
	if(what == NOTIFICATION_PREDELETE):
		clean_TEMP()

# Creates an empty save in a given destionation
func create_empty_save(MapName:String, folderPath:String, TileMaps:Array) -> bool:
	var sqlsave := SQLSave.new(MapName, folderPath)
	return sqlsave.create_new_save(TileMaps)

# Loads a given map
func _load_map(MapName:String, TileMaps:Array) -> bool:
	var Temp := SQLSave.new(MapName, MAP_FOLDER)
	if(not Temp.load(TileMaps)):
		return false
	_CurrentMap = Temp
	return true

# Loads a given map with corresponding save
func load_sav(SaveName:String, MapName:String, TileMaps:Array) -> bool:
	if(not _load_map(MapName, TileMaps)):
		Logger.logErr(["Failed to load map: ", MapName], get_stack())
		return false
	
	var Temp := SQLSave.new(SaveName, SAV_FOLDER)
	if(not Temp.load(TileMaps)):
		Logger.logErr(["Failed to load sav: ", SaveName], get_stack())
		return false
	_CurrentSav = Temp
	return true

func save_sav(SaveName:String) -> bool:
	return _CurrentSav.save(SAV_FOLDER + SaveName + ".db")
func _save_map(MapName:String) -> bool:
	return _CurrentMap.save(MAP_FOLDER + MapName + ".db")
func _delete_map(MapName:String = "") -> int:
	return SQLSave.delete_SQLDB_file(MAP_FOLDER, MapName)
func delete_sav(SaveName:String = "") -> int:
	return SQLSave.delete_SQLDB_file(SAV_FOLDER, SaveName)

# Temp file clean wrapper, cleans all TEMP files created by SaveManager
func clean_TEMP() -> bool:
	var isOK := true
	isOK = isOK and SQLSave.clean_TEMP(MAP_FOLDER)
	isOK = isOK and SQLSave.clean_TEMP(SAV_FOLDER)
	return isOK

### ----------------------------------------------------
### Set / get / Remove API
### ----------------------------------------------------


# Wrapper function, sets TileData in _CurrentSav
func set_TileData_on(posV3:Vector3, tileData:TileData) -> bool:
	return _CurrentSav.set_TileData_on(posV3, tileData)

# Wrapper function, removes TileData in _CurrentSav
func remove_TileData_on(posV3:Vector3) -> bool:
	return _CurrentSav.remove_TileData_on(posV3)

# Wrapper function, adds tile in _CurrentSav
func add_tile_to_TileData(posV3:Vector3, TSName:String, tileID:int) -> bool:
	return _CurrentSav.add_tile_to_TileData_on(posV3, TSName, tileID)

# Wrapper function, adds Entity in _CurrentSav
func add_Entity_to_TileData(posV3:Vector3, entity:GameEntity) -> bool:
	return _CurrentSav.add_Entity_to_TileData(posV3, entity)

# Wrapper function, remove tile in _CurrentSav
func remove_tile_from_TileData(TSName:String, posV3:Vector3) -> bool:
	return _CurrentSav.remove_tile_from_TileData(TSName, posV3)

# Wrapper function, remove entity in _CurrentSav
func remove_Entity_from_TileData(posV3:Vector3) -> bool:
	return _CurrentSav.remove_Entity_from_TileData(posV3)

# Wrapper function, checks if TileData was edited in _CurrentSav, if not get tile from _CurrentMap
func get_TileData_on(posV3:Vector3) -> TileData:
	var savResult := _CurrentSav.get_TileData_on(posV3)
	if(savResult.is_empty()): return _CurrentMap.get_TileData_on(posV3)
	return savResult

# Wrapper function, checks if TileData was edited in _CurrentSav, if not get tile from _CurrentMap
func get_TileData_on_chunk(chunkPosV3:Vector3, chunkSize:int) -> Dictionary:
	var savResult := _CurrentSav.get_TileData_on_chunk(chunkPosV3, chunkSize)
	savResult.merge(_CurrentMap.get_TileData_on_chunk(chunkPosV3, chunkSize))
	return savResult

func get_PlayerEntity() -> PlayerEntity:
	return _CurrentSav.get_PlayerEntity()

func set_PlayerEntity(Player:PlayerEntity) -> bool:
	return _CurrentSav.set_PlayerEntity(Player)
