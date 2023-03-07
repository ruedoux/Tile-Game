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
	if(caller == null): return
	push_error("FIX, variables are not properlu copied to states")
	for propertyInfo in get_script().get_script_property_list():
		if(propertyInfo.name == "Caller"):
			continue
		if(not Caller.has_method(propertyInfo.name)):
			var node:Node = Caller.get_node_or_null(propertyInfo.name)
			if(node != null):
				set(propertyInfo.name, node)
			continue
		set(propertyInfo.name, Caller.get(propertyInfo.name))
		print(propertyInfo.name)

# Called whenever a state is set as current by StateMachine
func _state_set() -> void:
	pass

# Returns name of a state, needs to be overwriten
static func get_name() -> String:
	Logger.logErr(["Function should be overwriten! "], get_stack())
	return "Not Setup"

# For physics process
func update_delta(_delta:float):
	Logger.logErr(["Function should be overwriten! "], get_stack())

# For input event
func update_input(_event:InputEvent):
	Logger.logErr(["Function should be overwriten! "], get_stack())
