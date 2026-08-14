extends Node3D

signal runtime_ready

const VERSION := "0.4.2-chapter-one-demo"

var campaign := CampaignState.new()
var recruitment := RecruitmentManager.new()
var roster := RosterManager.new()
var training := TrainingManager.new()
var progression := ProgressionManager.new()
var saves := SaveManager.new()
var demo := DemoDirector.new()
var board := BoardController.new()
var encounter := EncounterController.new()
var match_controller := MatchController.new()
var camera := Camera3D.new()
var ui := CampaignUI.new()
var story := StoryOverlay.new()
var tutorial := TutorialOverlay.new()

func _ready() -> void:
    _setup_world()
    _setup_systems()
    recruitment.load_pool()
    training.setup(campaign)
    _setup_ui()
    _setup_demo_surfaces()
    ui.visible = false
    tutorial.hide_guide()
    var session_mode := str(ProjectSettings.get_setting("battleboard/session_mode", "new"))
    if session_mode == "continue" and saves.has_save():
        _continue_demo()
    else:
        _new_demo()
    runtime_ready.emit()

func _setup_systems() -> void:
    for node in [campaign, recruitment, roster, training, progression, saves, demo, board, encounter, match_controller]:
        add_child(node)
    board.setup(camera)
    match_controller.setup(board)
    match_controller.encounter_requested.connect(_on_encounter_requested)
    match_controller.status_changed.connect(_on_match_status)
    match_controller.match_finished.connect(_on_match_finished)
    encounter.resolved.connect(_on_encounter_resolved)
    encounter.status_changed.connect(_on_match_status)

func _setup_world() -> void:
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-58, -28, 0)
    key.light_energy = 1.05
    key.shadow_enabled = true
    add_child(key)
    var rim := OmniLight3D.new()
    rim.position = Vector3(-8, 7, 4)
    rim.omni_range = 22.0
    rim.light_energy = 4.0
    rim.light_color = Color("#6d82a4")
    add_child(rim)
    var warm := OmniLight3D.new()
    warm.position = Vector3(8, 5, -5)
    warm.omni_range = 17.0
    warm.light_energy = 3.0
    warm.light_color = Color("#a66b53")
    add_child(warm)
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#0b1017")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#9aa9bf")
    env.ambient_light_energy = 0.48
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    add_child(world)
    ArenaBuilder.build(self)
    camera.position = Vector3(0, 20.5, 18.5)
    camera.fov = 48
    add_child(camera)
    camera.look_at(Vector3.ZERO, Vector3.UP)

func _setup_ui() -> void:
    add_child(ui)
    ui.setup(campaign, recruitment, roster, training, progression)
    ui.recruit_requested.connect(_recruit)
    ui.train_requested.connect(_train)
    ui.assign_requested.connect(_assign)
    ui.start_match_requested.connect(_start_match)
    ui.save_requested.connect(_save)

func _setup_demo_surfaces() -> void:
    add_child(story)
    add_child(tutorial)
    story.setup()
    tutorial.setup()
    story.sequence_finished.connect(_on_story_finished)

func _new_demo() -> void:
    saves.delete_save()
    _reset_campaign_runtime()
    ui.visible = true
    ui.show_hq()
    tutorial.hide_guide()
    _save()
    story.show_sequence("opening")

func _continue_demo() -> void:
    recruitment.load_pool()
    if not saves.load_campaign(campaign, recruitment, roster, training, progression):
        _new_demo()
        return
    ui.visible = true
    ui.show_hq()
    if not campaign.intro_seen:
        story.show_sequence("opening")
    else:
        _advance_demo()

func _reset_campaign_runtime() -> void:
    campaign.reset_demo()
    recruitment.load_pool()
    roster.clear()
    training.sessions.clear()
    progression.xp.clear()
    progression.knockouts.clear()
    progression.injuries.clear()
    _seed_new_campaign()

func _seed_new_campaign() -> void:
    for profile_id in ["hana", "ren", "goro", "mira", "sora"]:
        var profile := recruitment.recruit(profile_id)
        roster.add_profile(profile)
    roster.assign("goro", "king")
    roster.assign("mira", "bishop")
    roster.assign("hana", "knight")
    roster.assign("ren", "pawn")
    roster.assign("sora", "pawn")

func _recruit(profile_id: String) -> void:
    var profile: BBProfile = recruitment.available.get(profile_id)
    if profile == null:
        return
    var cost := recruitment.recruit_cost(profile)
    if not campaign.spend(cost):
        return
    profile = recruitment.recruit(profile_id)
    roster.add_profile(profile)
    ui.select_profile(profile_id)
    _changed()

func _train(profile_id: String, role: String) -> void:
    var profile: BBProfile = roster.roster.get(profile_id)
    if training.train(profile, role):
        _changed()

func _assign(profile_id: String, role: String) -> void:
    if roster.assign(profile_id, role):
        _changed()

func _start_match() -> void:
    var state := demo.evaluate(campaign, roster, training)
    if not bool(state.get("qualifier_open", false)):
        _advance_demo()
        return
    if not roster.is_qualification_ready():
        return
    campaign.phase = "match"
    tutorial.hide_guide()
    ui.show_match("ASHLINE LOCAL QUALIFIER · Entering arena")
    match_controller.start_match(roster.assigned_profiles(), roster.assignments)
    _save()

func _on_match_finished(won: bool, summary: String, defeated_ids: Array[String]) -> void:
    var active_profiles := roster.assigned_profiles()
    var notices := progression.award_match(active_profiles, won, defeated_ids)
    campaign.record_result(won)
    _save()
    var extra := ""
    if not notices.is_empty():
        extra = "\n" + "\n".join(PackedStringArray(notices))
    ui.show_result(won, "%s\nCrowns %d · Reputation %d%s" % [summary, campaign.crowns, campaign.reputation, extra])
    if won and not campaign.ending_seen:
        get_tree().create_timer(0.8).timeout.connect(_show_victory_story)
    else:
        _advance_demo()

func _show_victory_story() -> void:
    story.show_sequence("victory")

func _on_story_finished(sequence_id: String) -> void:
    if sequence_id == "opening":
        campaign.intro_seen = true
    elif sequence_id == "victory":
        campaign.ending_seen = true
        campaign.demo_completed = true
    _save()
    _advance_demo()

func _on_encounter_requested(context: BBEncounterContext) -> void:
    encounter.start(context, board, camera)

func _on_encounter_resolved(winner: String, loser: String, destination: Vector2i) -> void:
    match_controller.resolve_encounter(winner, loser, destination)

func _on_match_status(text: String) -> void:
    ui.update_match_status(text)

func _changed() -> void:
    _save()
    _advance_demo()

func _advance_demo() -> void:
    var state := demo.evaluate(campaign, roster, training)
    campaign.objective = str(state.get("hint", ""))
    ui.refresh()
    ui.start_button.disabled = not bool(state.get("qualifier_open", false)) or not roster.is_qualification_ready()
    if campaign.phase == "hq" and not story.is_open():
        tutorial.show_stage(str(state["stage"]), str(state["hint"]), int(state["step"]), int(state["total"]))

func _save() -> void:
    saves.save_campaign(campaign, recruitment, roster, training, progression)
