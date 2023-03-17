### ----------------------------------------------------
### Desc
### ----------------------------------------------------

extends SMState
class_name PlayerMove

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

signal PlayerMoved(posV2)

const INPUT_COOLDOWN := 150
var InputDelayer := STimer.new()

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func _init(caller:Node2D).(caller) -> void:
	pass

func move_player(direction:Vector3) -> void:
	if(not InputDelayer.time_from_start(INPUT_COOLDOWN)):
		return
	
	Caller.MapPosition += direction * GLOBAL.TILEMAPS.BASE_SCALE
	emit_signal("PlayerMoved", LibK.Vectors.vec3_vec2(Caller.MapPosition))
	InputDelayer.start()

func update_input(_event:InputEvent) -> void:
	pass

func update_delta(_delta:float) -> void:
	if(Input.is_action_pressed("Left")):
		move_player(Vector3.LEFT)
	elif(Input.is_action_pressed("Right")):
		move_player(Vector3.RIGHT)
	elif(Input.is_action_pressed("Up")):
		move_player(Vector3.DOWN)
	elif(Input.is_action_pressed("Down")):
		move_player(Vector3.UP)

static func get_name() -> String:
	return "PlayerMove"
