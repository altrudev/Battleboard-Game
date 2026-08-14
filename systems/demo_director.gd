class_name DemoDirector
extends Node

var current_stage := "intro"
var current_hint := ""

func evaluate(campaign: CampaignState, roster: RosterManager, training: TrainingManager) -> Dictionary:
    if not campaign.intro_seen:
        return _set("intro", "Listen to the registration intake and learn what the Bronze circuit requires.", 1, false)
    if roster.roster.size() < 8:
        return _set("recruit", "Scout the market and recruit until your stable reaches eight fighters. Build for the missing roles, not just the highest rating.", 2, false)
    if training.sessions.is_empty():
        return _set("train", "Select a fighter in your stable and train the role you intend them to hold. Training changes position aptitude rather than locking a class.", 3, false)
    if not roster.is_qualification_ready():
        return _set("assign", "Assign a complete Bronze Board: King, Queen, Rook, Bishop, Knight, and three Pawns. Watch individual fit and team affinity.", 4, false)
    if campaign.qualifier_wins < 1:
        return _set("qualifier", "Your Bronze Board is legal. Enter the Ashline local qualifier and earn the registration seal.", 5, true)
    return _set("complete", "Chapter One complete. Your board is registered; the save preserves roster growth, relationships, training and injuries.", 6, true)

func _set(stage: String, hint: String, step: int, gate_open: bool) -> Dictionary:
    current_stage = stage
    current_hint = hint
    return {
        "stage": stage,
        "hint": hint,
        "step": step,
        "total": 6,
        "qualifier_open": gate_open,
    }
