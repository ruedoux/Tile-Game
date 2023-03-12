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

# Reference to the player
var PlayerRef:PlayerEntity

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func load_player(Player:PlayerEntity) -> void:
	PlayerRef = Player
	add_child(Player)

# Loads entities on a given chunk and drops them as a child node
func load_entities_on_chunk(chunkV3:Vector3, DataDict:Dictionary) -> void:
	for posV3 in DataDict:
		var tileData:TileData = DataDict[posV3]
		if(tileData.EntityData.empty()): continue
		print("ENTITY EXIST: ", chunkV3)
		var NewEntity:GameEntity = GameEntity.new().from_str(tileData.EntityData)
		if(not connect("unloaded_chunk", NewEntity, "unload_entity") == OK):
			Logger.logErr(["Failed to connect entity to EntityManager, pos: ", [posV3, NewEntity]], get_stack())
			continue
		add_child(NewEntity)
		SaveManager.remove_Entity_from_TileData(posV3)
	
	RenderedChunks.append(chunkV3)

# Call a signal to unload all entities on this chunk
# all entities listen to this signal and unload themselves on it
func unload_chunk(chunkV3:Vector3) -> void:
	emit_signal("unloaded_chunk", chunkV3)

# Calls all entities to unload
func unload_all_chunks():
	for chunkV3 in RenderedChunks:
		unload_chunk(chunkV3)

# Saves all entities on the map
func save_all_entities():
	for entity in get_children():
		if(not entity is GameEntity):
			Logger.logErr(["entity is not GameEntity: ", entity.get_name()], get_stack())
			continue
		entity.save_entity()
	Logger.logMS(["All entities saved, saved amount: ", get_child_count()])