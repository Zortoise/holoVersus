extends CanvasLayer

var rolled_back_frames := 0
var rb_indicator_reset_timer := 0

const RB_RESET_TIME = 60


func _physics_process(_delta):
	if visible:
		var new_text = str(Engine.get_frames_per_second())+ " FPS" 
		$Fps.text = new_text
		
		if Netplay.is_netplay():
			if Netplay.ping != null:
				$Netplay/Ping.text = "P:" + str(round(Netplay.ping * 1000)) + "ms"
			else:
				$Netplay/Ping.text = ""
				
			if Netcode.game_ongoing:
				$Netplay/Delay.text = "D:" + str(Netcode.input_delay) + "f"
				$Netplay/Rollback.text = "R:" + str(rolled_back_frames) + "f"
				if Netcode.time_diff > 0:
					$Netplay/TimeDiff.text = "T:+" + str(Netcode.time_diff) + "f"
				elif Netcode.time_diff < 0:
					$Netplay/TimeDiff.text = "T:" + str(Netcode.time_diff) + "f"
				else:
					$Netplay/TimeDiff.text = "T:0f"
			else:
				$Netplay/Delay.text = ""
				$Netplay/Rollback.text = ""
				$Netplay/TimeDiff.text = ""
				
		else:
			for x in $Netplay.get_children():
				x.text = ""
				
		rb_indicator_reset_timer += 1
		if rb_indicator_reset_timer > RB_RESET_TIME: # if no update to rolled_back_frames after 1 sec, set it to 0
			rolled_back_frames = 0
				
				
func set_rolled_back_frames(in_rolled_back_frames):
	rolled_back_frames = in_rolled_back_frames
	rb_indicator_reset_timer = 0
	

