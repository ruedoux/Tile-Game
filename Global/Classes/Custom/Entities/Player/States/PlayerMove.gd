### ----------------------------------------------------
### Desc
### ----------------------------------------------------

extends SMState
class_name PlayerMove

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

signal PlayerMoved(posV2)

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func _init(caller:Node2D).(caller) -> void:
	pass

func move_player(direction:Vector3) -> void:
	Caller.MapPosition += direction * GLOBAL.TILEMAPS.BASE_SCALE
	emit_signal("PlayerMoved", LibK.Vectors.vec3_vec2(Caller.MapPosition))

func update_input(event:InputEvent) -> void:
	if(event.is_action_pressed("Left")):
		move_player(Vector3.LEFT)
	elif(event.is_action_pressed("Right")):
		move_player(Vector3.RIGHT)
	elif(event.is_action_pressed("Up")):
		move_player(Vector3.DOWN)
	elif(event.is_action_pressed("Down")):
		move_player(Vector3.UP)

static func get_name() -> String:
	return "PlayerMove"
