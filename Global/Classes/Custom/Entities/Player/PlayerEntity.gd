### ----------------------------------------------------
### Player data class
### ----------------------------------------------------

extends GameEntity
class_name PlayerEntity

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

var PlayerStateMachine := StateMachine.new()
var Movement := PlayerMove.new(self)

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func _on_entity_ready() -> void:
	set_sprite(TexturePos, GLOBAL.TEXTURES.ENTITY_SET_PATH)
	PlayerStateMachine.add_state(Movement)
	PlayerStateMachine.set_state(Movement)
	PlayerStateMachine.add_default_state(Movement)

func _input(event:InputEvent) -> void:
	PlayerStateMachine.update_state_input(event)

func _physics_process(delta: float) -> void:
	PlayerStateMachine.update_state_delta(delta)

# Saves this entity
func save_entity() -> bool:
	return SaveManager.set_PlayerEntity(self)
