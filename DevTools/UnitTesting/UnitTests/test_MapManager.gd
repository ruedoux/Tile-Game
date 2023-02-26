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

func before_each():
	MapManager = _MM.instance()
	add_child(MapManager)
	var TileMaps:Array = $MapManager/TileMapManager.TileMaps
	if(not SaveManager._create_empty_save(SAVE_NAME, SaveManager.MAP_FOLDER, TileMaps)):
		push_error("Failed to init unit test")
		get_tree().quit()
	if(not SaveManager._create_empty_save(SAVE_NAME, SaveManager.SAV_FOLDER, TileMaps)):
		push_error("Failed to init unit test")
		get_tree().quit()

func after_each():
	assert_true(SaveManager.delete_sav(SAVE_NAME) == OK, "Failed to delete save: " + SAVE_NAME)
	assert_true(SaveManager._delete_map(SAVE_NAME) == OK, "Failed to delete map: " + SAVE_NAME)
	MapManager.queue_free()

func test_EntityManager():
	var FocusEntity := GameEntity.new()
	assert_true(MapManager.start_simulation(SAVE_NAME, SAVE_NAME), "Failed to start simulation")
	#assert_true(SaveManager.add_Entity_to_TileData(Vector3(0,0,0), FocusEntity))

	FocusEntity.queue_free()
