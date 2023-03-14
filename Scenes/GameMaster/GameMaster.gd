### ----------------------------------------------------
### Desc
### ----------------------------------------------------
extends Node

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------


func create_new_save() -> bool:
	if(not SaveManager.create_empty_save("test", SaveManager.SAV_FOLDER, $MapManager/TileMapManager.TileMaps)):
		Logger.logErr(["Failed to create_new_save"], get_stack())
		return false
	return true

func start_game():
	create_new_save()
	if(not $MapManager.start_simulation("test", "test")):
		push_error("Failed to init")
		get_tree().quit()

func _ready() -> void:
	start_game()
	
	
	
