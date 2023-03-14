### ----------------------------------------------------
### Class used as a template object for all state machines:
### - Create state machine object with classes that manage coresponding states
### ----------------------------------------------------

extends Reference
class_name StateMachine

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

const ERROR = "ERROR_DEFAULT"

var verbose := false

# Describes currently set state of the state machine
var CurrentState:SMState

# Shortcut to default state
var DefaultState:SMState

# StateName [State Reference, ...]
var StateTable := Array()

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func _init(verbosity:bool = false) -> void:
	verbose = verbosity

# Adds state to StateTable and inits it
func add_state(State:SMState) -> void:  
	State.StateMaster = self
	if(verbose):
		Logger.logMS(["Added new state: ", State.get_name()])
	StateTable.append(State)

# Sets a given state as current
func set_state(State:SMState) -> bool:
	if(not StateTable.has(State)):
		Logger.logErr(["State not in Statetable, add it first with add_state(), ", State], get_stack())
		return false
	if(verbose): 
		Logger.logMS(["Set new state: ", State])
	CurrentState = State
	CurrentState._state_set()
	return true

# Adds default state for state machine (easy access to default state)
func add_default_state(State:SMState) -> bool:
	if(not StateTable.has(State)):
		Logger.logErr(["State not in Statetable, add it first with add_state(), ", State], get_stack())
		return false
	if(verbose): 
		Logger.logMS(["Set default state: ", State])
	DefaultState = State
	return true

# Sets DefaultState as CurrentState
func set_default_state() -> bool:
	if(DefaultState == null):
		Logger.logErr(["Failed to set default state (null)"], get_stack())
		return false
	set_state(DefaultState)
	return true

# Wrapper to call update_delta of current state
func update_state_delta(delta:float) -> void:
	CurrentState.update_delta(delta)

# Wrapper to call update_input of current state
func update_state_input(event:InputEvent) -> void:
	CurrentState.update_input(event)

# Calls function of a given state and return the result, meant to be used for signals redirection
func redirect_signal(State:SMState, functionName:String, argArr:Array):
	if(not StateTable.has(State)):
		Logger.logErr(["State not in StateTable, add it first with add_state(), ", State], get_stack())
		return ERROR
	if(not State == CurrentState):
		Logger.logErr(["Sent signal to a state that is not currently set but exists in StateTable, ", State, " ", functionName], get_stack())
		return ERROR
	if(not CurrentState.has_method(functionName)):
		Logger.logErr(["State is missing function ", State, " ", functionName], get_stack())
		return ERROR
	return funcref(CurrentState, functionName).call_funcv(argArr)

# Calls function of a given state regardless if its a current state
func force_call(State:SMState, functionName:String, argArr:Array):
	if(not StateTable.has(State)):
		Logger.logErr(["State not in StateTable, add it first with add_state(), ", State], get_stack())
		return ERROR
	if(not State.has_method(functionName)):
		Logger.logErr(["State is missing function ", State, " ", functionName], get_stack())
		return ERROR
	return funcref(State, functionName).call_funcv(argArr)
