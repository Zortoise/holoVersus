extends Control

signal popup_vanished()

var presets = {
	1 : "Connection Issue:\nConnection Ended",
	2 : "Connection Issue:\nOpponent Disconnected",
	3 : "Connection Issue:\nAttempting to start rollback over Max Rollback allowed",
	4 : "Connection Issue:\nGap in input detected",
	5 : "Connection Issue:\nNo response from opponent",
	6 : "Connection Issue:\nPositions desynchronized",
	7 : "Connection Issue:\nSaved positions not found",
}


func init(in_text):
	Netcode.game_ongoing = false
	get_tree().paused = true
	if in_text is String:
		$CanvasLayer/Label.text = in_text
	if in_text is int:
		$CanvasLayer/Label.text = presets[in_text]
	$CanvasLayer/AnimationPlayer.play("fading")


func _on_AnimationPlayer_animation_finished(_anim_name):
	get_tree().paused = false
	emit_signal("popup_vanished")
	queue_free()
