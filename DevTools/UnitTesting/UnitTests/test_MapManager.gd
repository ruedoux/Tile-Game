### ----------------------------------------------------
### Desc
### ----------------------------------------------------
extends GutTestLOG

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

const SAVE_NAME = "UnitTest"
const _MM = preload("res://Scenes/MapManager/MapManager.tscn")
var MapManager:Node = null

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func before_all():
	MapManager = _MM.instance()
	add_child(MapManager)

func after_all():
	MapManager.queue_free()

func before_each():
	print($MapManager/TileMapManager)
	var TileMaps:Array = $MapManager/TileMapManager.TileMaps
	if(not SaveManager._create_empty_save(SAVE_NAME, SaveManager.MAP_FOLDER, TileMaps)):
		push_error("Failed to init unit test")
		get_tree().quit()
	if(not SaveManager._create_empty_save(SAVE_NAME, SaveManager.SAV_FOLDER, TileMaps)):
		push_error("Failed to init unit test")
		get_tree().quit()
	assert_true(MapManager.start_simulation(SAVE_NAME, SAVE_NAME), "Failed to start simulation")

func after_each():
	assert_true(SaveManager.delete_sav(SAVE_NAME) == OK, "Failed to delete save: " + SAVE_NAME)
	assert_true(SaveManager._delete_map(SAVE_NAME) == OK, "Failed to delete map: " + SAVE_NAME)
	assert_true(SaveManager.clean_TEMP(), "Failed to clean TEMP")
	print_stray_nodes()

func test_MapManager():
	assert_true(MapManager.LoadedChunks.size() == pow(MapManager.SIM_RANGE*2+1, 3), "LoadedChunks size doesnt match: "+ str(pow(MapManager.SIM_RANGE*2+1, 3)))
	assert_true(MapManager.GameFocusEntity is PlayerEntity, "GameFocusEntity is not PlayerEntity")
	assert_true(MapManager.SimulatedEntities.size() == 1)

func test_EntityManager():
	var ENUM = 10 # Make sure to be in range of render
	for i in range(1,ENUM):
		var entity := GameEntity.new()
		assert_true(SaveManager.add_Entity_to_TileData(Vector3(i+1,0,0), entity))
		entity.queue_free()
	
	MapManager.update_simulation()
	
	assert_true($MapManager/EntityManager.get_child_count() == ENUM, "Entity count should be equal to expected")
	LOG_GUT(["Enity count: ", $MapManager/EntityManager.get_child_count(), ", expected: ", ENUM])
	LOG_GUT([$MapManager/EntityManager.get_children()])
