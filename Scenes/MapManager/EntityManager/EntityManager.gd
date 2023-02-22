### ----------------------------------------------------
### Manages all entities
### ----------------------------------------------------

extends Node2D

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

var RenderedChunks := Array()

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------


# Loads entities on a given chunk
func load_entities_on_chunk(chunkV3:Vector3, DataDict:Dictionary) -> void:
    for posV3 in DataDict:
        var tileData:TileData = DataDict[posV3]
        if(tileData.EntityData.empty()): continue
        add_child(GameEntity.new().from_str(tileData.EntityData))
        SaveManager.remove_Entity_from_TileData(posV3)
    RenderedChunks.append(chunkV3)
