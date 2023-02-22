### ----------------------------------------------------
### Base class of all in game entities
### ----------------------------------------------------

extends Sprite
class_name GameEntity

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

const SPRITE_SET_PATH = "res://Resources/Textures/EntitySet.png"

# Position on the game map
var MapPosition := Vector3(0,0,0) setget _set_MapPosition
func _set_MapPosition(posV3:Vector3):
	global_position = LibK.Vectors.vec3_vec2(posV3)
	MapPosition = posV3

# Position of the sprite on texture set
var TexturePos := Vector2(0,0)

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func _ready() -> void:
	set_sprite(TexturePos, SPRITE_SET_PATH)

# Loads sprite from sprite set
func set_sprite(spritePos:Vector2, texturePath:String) -> void:
	var setTexture:Texture = ResourceLoader.load(texturePath, "Texture")
	texture = LibK.Img.get_sprite_from_texture(spritePos, DATA.TILEMAPS.TILE_SIZE, setTexture)

### ----------------------------------------------------
# Utils
### ----------------------------------------------------

# Creates a copy of entity from its data string
func from_str(s:String):
	return from_array(str2var(s))

# Creates copy of entity data as string
func _to_string() -> String:
	return var2str(to_array())

# Converts entity data to an array
func to_array() -> Array:
	var arr := []
	for propertyInfo in get_script().get_script_property_list():
		arr.append(get(propertyInfo.name))
	return arr

# Creates copy of entity data as Array
func from_array(arr:Array):
	var index := 0
	for propertyInfo in get_script().get_script_property_list():
		set(propertyInfo.name, arr[index])
		index+=1
	return self