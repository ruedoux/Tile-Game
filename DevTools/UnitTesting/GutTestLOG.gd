### ----------------------------------------------------
### Decorator for my unit tests
### ----------------------------------------------------
extends GutTest
class_name GutTestLOG

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func LOG_GUT(text:String, nl:bool = false):
	if nl: gut.p("\n")
	gut.p("-----------------------------------------")
	gut.p(text.to_upper())
	gut.p("-----------------------------------------")