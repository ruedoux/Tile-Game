### ----------------------------------------------------
### Manages all entities
### ----------------------------------------------------

extends Node2D

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

# Keeps track of what chunks were rendered, emits a signal when chunk is unloaded
var RenderedChunks := Array()
signal unloaded_chunk(chunkV3)

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------


# Loads entities on a given chunk and drops them as a child node
func load_entities_on_chunk(chunkV3:Vector3, DataDict:Dictionary) -> void:
    for posV3 in DataDict:
        var tileData:TileData = DataDict[posV3]
        if(tileData.EntityData.empty()): continue
        add_child(GameEntity.new().from_str(tileData.EntityData))
        SaveManager.remove_Entity_from_TileData(posV3)
    RenderedChunks.append(chunkV3)

# Call a signal to unload all entities on this chunk
# all entities listen to this signal and unload themselves on it
func unload_entities_on_chunk(chunkV3:Vector3) -> void:
    emit_signal("unloaded_chunk", chunkV3)