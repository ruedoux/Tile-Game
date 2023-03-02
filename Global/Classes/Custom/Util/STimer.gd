### ----------------------------------------------------
### One time use util timer
### ----------------------------------------------------

extends Reference
class_name STimer

### ----------------------------------------------------
### VARIABLES
### ----------------------------------------------------

var startTime:int

### ----------------------------------------------------
### FUNCTIONS
### ----------------------------------------------------

func _init() -> void:
	startTime = Time.get_ticks_msec()


func get_result():
	return (Time.get_ticks_msec() - startTime)
