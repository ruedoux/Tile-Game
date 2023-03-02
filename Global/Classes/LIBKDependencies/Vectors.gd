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
	return Vector2(floor(v[0]/(scale)), floor(v[1]/(scale)))

static func scale_down_vec3(v:Vector3, scale:int) -> Vector3:
	return Vector3(floor(v[0]/(scale)), floor(v[1]/(scale)), v[2])

static func vec2_get_pos_in_chunk(chunkV:Vector2, chunkSize:int) -> Array:
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
