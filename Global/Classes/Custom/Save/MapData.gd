### ----------------------------------------------------
# Cache for MapData
### ----------------------------------------------------

extends Reference
class_name MapData

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

# { ChunkPos:{posV3:TileData} }
var Data := Dictionary()

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

# Sets TileData in Data on posV3
func set_in_Data(ChunkPos:Vector2, posV3:Vector3, tileData:TileData) -> void:
	if(not Data.has(ChunkPos)):
		Data[ChunkPos] = {}
	Data[ChunkPos][posV3] = str(tileData)

# Gets TileData on position from Data
func get_in_Data(ChunkPos:Vector2, posV3:Vector3) -> TileData:
	if(not Data.has(ChunkPos)):
		return TileData.new()
	if(not Data[ChunkPos].has(posV3)):
		return TileData.new()
	return TileData.new().from_str(Data[ChunkPos][posV3])

# Removes position from Data
func rem_in_Data(ChunkPos:Vector2, posV3:Vector3) -> bool:
	if(not Data.has(ChunkPos)):
		return false
	return Data[ChunkPos].erase(posV3)

# Returns a duplicate of whole chunk data
func get_in_Data_chunk(ChunkPos:Vector2) -> Dictionary:
	if(not Data.has(ChunkPos)):
		return {}
	return Data[ChunkPos].duplicate()

# Sets a dict on position
func set_in_Data_chunk(ChunkPos:Vector2, dict:Dictionary) -> void:
	Data[ChunkPos] = dict.duplicate()

func rem_in_Data_chunk(ChunkPos:Vector2) -> bool:
	return Data.erase(ChunkPos)
