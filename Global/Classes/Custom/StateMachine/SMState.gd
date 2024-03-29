### ----------------------------------------------------
### Template state, every state in inherited Statemachine should have these functions
### ----------------------------------------------------

extends Reference
class_name SMState

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------


# Caller aka StateMachine source class
var Caller:Node

# Parent state machine, reference used for switching states inside of a given state
var StateMaster

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

# Automatically assigns variables in State to variables in parent (by reference)
func _init(caller:Node) -> void:
	Caller = caller

# Called whenever a state is set as current by StateMachine
func _state_set() -> void:
	pass

# Set of instructions executed at the end of state, can be overwritten
func end_state() -> void:
	StateMaster.set_default_state()

# Returns name of a state
static func get_name() -> String:
	return "Unnamed State"

# For physics process
func update_delta(_delta:float) -> void:
	Logger.logErr(["Function should be overwriten! "], get_stack())

# For input event
func update_input(_event:InputEvent) -> void:
	Logger.logErr(["Function should be overwriten! "], get_stack())

func _to_string() -> String:
	return get_name()