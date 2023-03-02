### ----------------------------------------------------
### Desc
### ----------------------------------------------------
extends GutTestLOG

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

const _TMM = preload("res://Scenes/MapManager/TileMapManager/TileMapManager.tscn")
var TileMapManager:Node = null

const SAV_FOLDER := "res://Temp/"
const SAV_NAME := "UnitTest"

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func before_each():
	TileMapManager = autoqfree(_TMM.instance())
	add_child(TileMapManager)

func get_regular(sqlsave:SQLSave, TestPosV3:Array, SavedData:Dictionary) -> void:
	var GetTimer = STimer.new()
	for posV3 in TestPosV3:
		var GetTD := sqlsave.get_TileData_on(posV3)
		assert_true(str(SavedData[posV3]) == str(GetTD), "Get TileData (create) content does not match: "+str(SavedData[posV3])+"=!"+str(GetTD)+", Pos:"+str(posV3))
	LOG_GUT(["Get time (msec) (regular): ", GetTimer.get_result()])

func get_bulk(sqlsave:SQLSave, TestChunks:Array, SavedData:Dictionary) -> void:
	var GetTimer = STimer.new()
	for chunkPosV3 in TestChunks:
		var ChunkData := sqlsave.get_TileData_on_chunk(chunkPosV3, SQLSave.MAPDATA_CHUNK_SIZE)
		for posV3 in ChunkData:
			assert_true(str(SavedData[posV3]) == str(ChunkData[posV3]), "Get TileData (create) content does not match: "+str(SavedData[posV3])+"=!"+str(ChunkData[posV3])+", Pos:"+str(posV3))
	LOG_GUT(["Get time (msec) (bulk): ", GetTimer.get_result()])

func test_SQLSave_TileData():
	var sqlsave := SQLSave.new(SAV_NAME, SAV_FOLDER)
	assert_true(sqlsave.create_new_save(TileMapManager.TileMaps))
	assert_true(sqlsave.load(TileMapManager.TileMaps), "Failed to init save")
	
	var RTileMap:TileMap = TileMapManager.TileMaps[randi()%TileMapManager.TileMaps.size()]
	var RTileMapName:String = RTileMap.get_name()
	var TileIds:Array = RTileMap.tile_set.get_tiles_ids()

	# Create a block of tiles to save
	var TestPosV3 := []
	var TestChunks := []
	
	for z in range(3):
		for x in range(1):
			for y in range(1):
				TestChunks.append(Vector3(x,y,z))
				TestPosV3.append_array(LibK.Vectors.vec3_get_pos_in_chunk(Vector3(x,y,z), SQLSave.MAPDATA_CHUNK_SIZE))
	
	# Set tiles in save and create a dict copy to compare to later
	var SavedData := {}
	var SetTimer = STimer.new()
	for posV3 in TestPosV3:
		var RTD := TileData.new({RTileMapName:TileIds[0]})
		assert_true(sqlsave.set_TileData_on(posV3, RTD), "Failed to set tile on position: "+str(posV3))
		SavedData[posV3] = TileData.new({RTileMapName:TileIds[0]})
	LOG_GUT(["Set time (msec): ", SetTimer.get_result()])
	
	# Get tiles from save
	get_regular(sqlsave, TestPosV3, SavedData)
	get_bulk(sqlsave, TestChunks, SavedData)
	
	assert_true(sqlsave.save(), "Failed to save")
	assert_true(sqlsave.MapData.size() == 0, "MapData should be empty! Size: " + str(sqlsave.MapData.size()))
	sqlsave = null
	
	# Simulate trying to access data after save
	var sqlload := SQLSave.new(SAV_NAME, SAV_FOLDER)
	assert_true(sqlload.load(TileMapManager.TileMaps), "Failed to initialize SQLSave on load")
	
	# Get tiles from save
	var LGetTimer = STimer.new()
	for posV3 in TestPosV3:
		var GetTD := sqlload.get_TileData_on(posV3)
		assert_true(str(SavedData[posV3]) == str(GetTD), "Get TileData (load) content does not match: "+str(SavedData[posV3])+"=!"+str(GetTD)+", Pos:"+str(posV3))
	LOG_GUT(["Get load time (msec): ", LGetTimer.get_result()])
	
	assert_true(SQLSave.delete_SQLDB_file(SAV_FOLDER, SAV_NAME) == OK, "Failed to delete save")

func test_SQLSave_Entity():
	var sqlsave := SQLSave.new(SAV_NAME, SAV_FOLDER, true)
	assert_true(sqlsave.create_new_save(TileMapManager.TileMaps))
	assert_true(sqlsave.load(TileMapManager.TileMaps), "Failed to init save")

	LOG_GUT(["Entity save test: "])
	var ENUM = 10 # Make sure to be in range of render
	var EntitySaved := {}
	for i in range(1,ENUM):
		var entity := GameEntity.new()
		var posV3 := Vector3(i+1,0,0)
		assert_true(sqlsave.add_Entity_to_TileData(posV3, entity))
		EntitySaved[posV3] = str(entity)
		entity.free()
	
	LOG_GUT(["Entity saved data test: "])
	for posV3 in EntitySaved:
		assert_true(EntitySaved[posV3] == sqlsave.get_TileData_on(posV3).EntityData, 
			str(EntitySaved[posV3]) + "=!" + str(sqlsave.get_TileData_on(posV3).EntityData))

	assert_true(SQLSave.delete_SQLDB_file(SAV_FOLDER, SAV_NAME) == OK, "Failed to delete save")
