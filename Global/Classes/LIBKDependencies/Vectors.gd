### ----------------------------------------------------
### Sublib for Vector related functions
### ----------------------------------------------------
extends Script

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------


static func vec3_get_range_2d(atPos:Vector3, squareRange:int) -> Array:
	var result := []
	for x in range(-squareRange, squareRange + 1):
		for y in range(-squareRange, squareRange + 1):
			result.append(Vector3(x,y,0) + atPos)
	return result

static func vec3_get_range_3d(atPos:Vector3, squareRange:int) -> Array:
	var result := []
	for x in range(-squareRange, squareRange + 1):
		for y in range(-squareRange, squareRange + 1):
			for z in range(-squareRange, squareRange + 1):
				result.append(Vector3(x,y,z) + atPos)
	return result

static func vec2_get_range(atPos:Vector2, squareRange:int) -> Array:
	var result := []
	for x in range(-squareRange, squareRange + 1):
		for y in range(-squareRange, squareRange + 1):
			result.append(Vector2(x,y) + atPos)
	return result

### ----------------------------------------------------
# Conversion Vector2 / Vector3
### ----------------------------------------------------


# Converts Vector2 to Vector3
static func vec2_vec3(v:Vector2, z:int = 0) -> Vector3:
	return Vector3(v.x, v.y, z)
	
#Converts Vector3 to Vector2
static func vec3_vec2(v:Vector3) -> Vector2:
	return Vector2(v.x, v.y)

### ----------------------------------------------------
# World to x (for Vector3 ommits third value)
### ----------------------------------------------------


static func scale_down_vec2(v:Vector2, scale:int) -> Vector2:
	return Vector2(v[0]/scale, v[1]/scale).floor()

static func scale_down_vec3(v:Vector3, scale:int) -> Vector3:
	return Vector3(v[0]/scale, v[1]/(scale), v[2]).floor()

# Optimization for creating chunk of vectors (more than 2 times faster)
const OPT16_CHUNK = [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3), Vector2(0, 4), Vector2(0, 5), Vector2(0, 6), Vector2(0, 7), Vector2(0, 8), Vector2(0, 9), Vector2(0, 10), Vector2(0, 11), Vector2(0, 12), Vector2(0, 13), Vector2(0, 14), Vector2(0, 15), Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(1, 3), Vector2(1, 4), Vector2(1, 5), Vector2(1, 6), Vector2(1, 7), Vector2(1, 8), Vector2(1, 9), Vector2(1, 10), Vector2(1, 11), Vector2(1, 12), Vector2(1, 13), Vector2(1, 14), Vector2(1, 15), Vector2(2, 0), Vector2(2, 1), Vector2(2, 2), Vector2(2, 3), Vector2(2, 4), Vector2(2, 5), Vector2(2, 6), Vector2(2, 7), Vector2(2, 8), Vector2(2, 9), Vector2(2, 10), Vector2(2, 11), Vector2(2, 12), Vector2(2, 13), Vector2(2, 14), Vector2(2, 15), Vector2(3, 0), Vector2(3, 1), Vector2(3, 2), Vector2(3, 3), Vector2(3, 4), Vector2(3, 5), Vector2(3, 6), Vector2(3, 7), Vector2(3, 8), Vector2(3, 9), Vector2(3, 10), Vector2(3, 11), Vector2(3, 12), Vector2(3, 13), Vector2(3, 14), Vector2(3, 15), Vector2(4, 0), Vector2(4, 1), Vector2(4, 2), Vector2(4, 3), Vector2(4, 4), Vector2(4, 5), Vector2(4, 6), Vector2(4, 7), Vector2(4, 8), Vector2(4, 9), Vector2(4, 10), Vector2(4, 11), Vector2(4, 12), Vector2(4, 13), Vector2(4, 14), Vector2(4, 15), Vector2(5, 0), Vector2(5, 1), Vector2(5, 2), Vector2(5, 3), Vector2(5, 4), Vector2(5, 5), Vector2(5, 6), Vector2(5, 7), Vector2(5, 8), Vector2(5, 9), Vector2(5, 10), Vector2(5, 11), Vector2(5, 12), Vector2(5, 13), Vector2(5, 14), Vector2(5, 15), Vector2(6, 0), Vector2(6, 1), Vector2(6, 2), Vector2(6, 3), Vector2(6, 4), Vector2(6, 5), Vector2(6, 6), Vector2(6, 7), Vector2(6, 8), Vector2(6, 9), Vector2(6, 10), Vector2(6, 11), Vector2(6, 12), Vector2(6, 13), Vector2(6, 14), Vector2(6, 15), Vector2(7, 0), Vector2(7, 1), Vector2(7, 2), Vector2(7, 3), Vector2(7, 4), Vector2(7, 5), Vector2(7, 6), Vector2(7, 7), Vector2(7, 8), Vector2(7, 9), Vector2(7, 10), Vector2(7, 11), Vector2(7, 12), Vector2(7, 13), Vector2(7, 14), Vector2(7, 15), Vector2(8, 0), Vector2(8, 1), Vector2(8, 2), Vector2(8, 3), Vector2(8, 4), Vector2(8, 5), Vector2(8, 6), Vector2(8, 7), Vector2(8, 8), Vector2(8, 9), Vector2(8, 10), Vector2(8, 11), Vector2(8, 12), Vector2(8, 13), Vector2(8, 14), Vector2(8, 15), Vector2(9, 0), Vector2(9, 1), Vector2(9, 2), Vector2(9, 3), Vector2(9, 4), Vector2(9, 5), Vector2(9, 6), Vector2(9, 7), Vector2(9, 8), Vector2(9, 9), Vector2(9, 10), Vector2(9, 11), Vector2(9, 12), Vector2(9, 13), Vector2(9, 14), Vector2(9, 15), Vector2(10, 0), Vector2(10, 1), Vector2(10, 2), Vector2(10, 3), Vector2(10, 4), Vector2(10, 5), Vector2(10, 6), Vector2(10, 7), Vector2(10, 8), Vector2(10, 9), Vector2(10, 10), Vector2(10, 11), Vector2(10, 12), Vector2(10, 13), Vector2(10, 14), Vector2(10, 15), Vector2(11, 0), Vector2(11, 1), Vector2(11, 2), Vector2(11, 3), Vector2(11, 4), Vector2(11, 5), Vector2(11, 6), Vector2(11, 7), Vector2(11, 8), Vector2(11, 9), Vector2(11, 10), Vector2(11, 11), Vector2(11, 12), Vector2(11, 13), Vector2(11, 14), Vector2(11, 15), Vector2(12, 0), Vector2(12, 1), Vector2(12, 2), Vector2(12, 3), Vector2(12, 4), Vector2(12, 5), Vector2(12, 6), Vector2(12, 7), Vector2(12, 8), Vector2(12, 9), Vector2(12, 10), Vector2(12, 11), Vector2(12, 12), Vector2(12, 13), Vector2(12, 14), Vector2(12, 15), Vector2(13, 0), Vector2(13, 1), Vector2(13, 2), Vector2(13, 3), Vector2(13, 4), Vector2(13, 5), Vector2(13, 6), Vector2(13, 7), Vector2(13, 8), Vector2(13, 9), Vector2(13, 10), Vector2(13, 11), Vector2(13, 12), Vector2(13, 13), Vector2(13, 14), Vector2(13, 15), Vector2(14, 0), Vector2(14, 1), Vector2(14, 2), Vector2(14, 3), Vector2(14, 4), Vector2(14, 5), Vector2(14, 6), Vector2(14, 7), Vector2(14, 8), Vector2(14, 9), Vector2(14, 10), Vector2(14, 11), Vector2(14, 12), Vector2(14, 13), Vector2(14, 14), Vector2(14, 15), Vector2(15, 0), Vector2(15, 1), Vector2(15, 2), Vector2(15, 3), Vector2(15, 4), Vector2(15, 5), Vector2(15, 6), Vector2(15, 7), Vector2(15, 8), Vector2(15, 9), Vector2(15, 10), Vector2(15, 11), Vector2(15, 12), Vector2(15, 13), Vector2(15, 14), Vector2(15, 15)]
static func _vec2_get_pos_in_chunk_opt16(chunkV:Vector2) -> Array:
	var result := []
	for vec in OPT16_CHUNK:
		result.append(vec+chunkV)
	return result

static func vec2_get_pos_in_chunk(chunkV:Vector2, chunkSize:int) -> Array:
	if(chunkSize == 16):
		return _vec2_get_pos_in_chunk_opt16(chunkV)
	var packedPositions := []
	for x in range(chunkSize):
		for y in range(chunkSize):
			packedPositions.append(Vector2(chunkV[0]*chunkSize + x, chunkV[1]*chunkSize + y))
	return packedPositions

static func vec3_get_pos_in_chunk(chunkV:Vector3, chunkSize:int) -> Array:
	var packedPositions := []
	for x in range(chunkSize):
		for y in range(chunkSize):
			packedPositions.append(Vector3(chunkV[0]*chunkSize + x, chunkV[1]*chunkSize + y, chunkV[2]))
	return packedPositions
