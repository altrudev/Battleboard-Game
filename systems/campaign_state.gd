class_name CampaignState
extends Node

signal changed

var crowns := 520
var reputation := 0
var training_tokens := 6
var qualifier_wins := 0
var qualifier_losses := 0
var match_number := 0
var phase := "hq"
var objective := "Assemble an 8-fighter Bronze Board and win the local qualifier."

func can_afford(amount: int) -> bool:
	return crowns >= amount

func spend(amount: int) -> bool:
	if not can_afford(amount): return false
	crowns -= amount
	changed.emit()
	return true

func add_crowns(amount: int) -> void:
	crowns += amount
	changed.emit()

func consume_training_token() -> bool:
	if training_tokens <= 0: return false
	training_tokens -= 1
	changed.emit()
	return true

func record_result(won: bool) -> void:
	match_number += 1
	if won:
		qualifier_wins += 1
		crowns += 240
		reputation += 12
		training_tokens += 2
	else:
		qualifier_losses += 1
		crowns += 70
		reputation += 3
		training_tokens += 1
	phase = "hq"
	changed.emit()

func to_dictionary() -> Dictionary:
	return {"crowns":crowns,"reputation":reputation,"training_tokens":training_tokens,"qualifier_wins":qualifier_wins,"qualifier_losses":qualifier_losses,"match_number":match_number,"phase":phase,"objective":objective}

func from_dictionary(data: Dictionary) -> void:
	crowns = int(data.get("crowns",520))
	reputation = int(data.get("reputation",0))
	training_tokens = int(data.get("training_tokens",6))
	qualifier_wins = int(data.get("qualifier_wins",0))
	qualifier_losses = int(data.get("qualifier_losses",0))
	match_number = int(data.get("match_number",0))
	phase = str(data.get("phase","hq"))
	objective = str(data.get("objective",objective))
	changed.emit()
