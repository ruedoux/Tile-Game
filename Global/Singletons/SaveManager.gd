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


func _create_empty_save(MapName:String, folderPath:String, TileMaps:Array) -> bool:
	var sqlsave := SQLSave.new(MapName, folderPath)
	return sqlsave.create_new_save(TileMaps)

func _load_map(MapName:String, TileMaps:Array) -> bool:
	var mapPath := MAP_FOLDER + MapName + ".db"
	if(not LibK.Files.file_exist(mapPath)):
		Logger.logErr(["Map doesnt exist: ", mapPath], get_stack())
		return false
	
	var isOK := true
	_CurrentMap = SQLSave.new(MapName, MAP_FOLDER)
	isOK = _CurrentMap.initialize() and isOK
	isOK = _CurrentMap.check_compatible(TileMaps) and isOK
	return isOK

func load_sav(SaveName:String, MapName:String, TileMaps:Array) -> bool:
	var isOK := _load_map(MapName, TileMaps)
	var savPath := SAV_FOLDER + SaveName + ".db"
	
	if(not isOK): return isOK
	if(not LibK.Files.file_exist(savPath)):
		Logger.logErr(["Save doesnt exist: ", savPath], get_stack())
		return false
	
	_CurrentSav = SQLSave.new(SaveName, SAV_FOLDER)
	isOK = _CurrentSav.initialize() and isOK
	isOK = _CurrentSav.check_compatible(TileMaps) and isOK
	return isOK

# Leave saveName empty if you want to overwrite save
func save_sav(SaveName:String) -> bool:
	return _CurrentSav.save_to_sqlDB(SAV_FOLDER + SaveName + ".db")

# Leave MapName empty if you want to overwrite map
func _save_map(MapName:String = "") -> bool:
	return _CurrentMap.save_to_sqlDB(MAP_FOLDER + MapName + ".db")

func _delete_map(MapName:String = "") -> int:
	return LibK.Files.delete_file(MAP_FOLDER + MapName + ".db")

func delete_sav(SaveName:String = "") -> int:
	return LibK.Files.delete_file(SAV_FOLDER + SaveName + ".db")

func delete_db(dbName:String, folderPath:String) -> int:
	return LibK.Files.delete_file(folderPath + dbName + ".db")

### ----------------------------------------------------
### Set / get / Remove
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
	var mapResult := _CurrentMap.get_TileData_on_chunk(chunkPosV3, chunkSize)
	for posV3 in savResult:
		if(savResult[posV3].is_empty()): savResult[posV3] = mapResult[posV3]
	return savResult
