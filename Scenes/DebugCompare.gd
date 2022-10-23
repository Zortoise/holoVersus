tool
extends EditorScript

var resource_A = "res://Scenes/SavedData/DebugLog0.tres"

var resource_B = "res://Scenes/SavedData/DebugLog1.tres"

func _run():
	var A_logs = ResourceLoader.load(resource_A).kborigin_logs
	var B_logs = ResourceLoader.load(resource_B).kborigin_logs
	
	if A_logs.hash() == B_logs.hash():
		print("They are the same.")
	else:
		print("They are not the same!")

		for timestamp in B_logs:
			if !timestamp is String:
				if !timestamp in A_logs:
					print("Missing timestamp: " + str(timestamp))
				else:
					if A_logs[timestamp] != B_logs[timestamp]:
						print("Discrepancy at: " + str(timestamp))
						print(str(A_logs[timestamp]))
						print(str(B_logs[timestamp]))
