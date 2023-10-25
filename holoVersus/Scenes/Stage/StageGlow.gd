extends Sprite

# set by script extending this
var modulate_start: Color
var modulate_end: Color
var period: float  # number of seconds for modulate to complete a cycle
var flicker_chance := 0.0 # chance to flicker every 1/60 second
var flicker_fade := 0.3 # how much to reduce alpha by when flickering

var time := 0.0 # float

# Example of code to enter in extended instance Sprite Node
#func _ready():
#
#	modulate_start = Color(1.0, 1.0, 1.0, 1.0)
#	modulate_end = Color(1.0, 1.0, 1.0, 0.3)
#	period = 5.0 # number of seconds for modulate to complete a cycle
#
#	init()

func init():
	time = Globals.random.randf() * period # randomize start point
	

func _physics_process(delta):
	
	if Globals.Game.is_stage_paused(): return
	
	time += delta
	if time > period:
		time = 0.0 # loop back
		
	var weight = (sin((time / period) * TAU) + 1) * 0.5 # get a value between 0 and 1 based on time
	modulate = lerp(modulate_start, modulate_end, weight)
	
	if Globals.random.randf() <= flicker_chance: # flickering
		modulate.a = max(modulate.a - flicker_fade, 0.0)

