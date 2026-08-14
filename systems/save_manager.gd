class_name SaveManager
extends Node

const SAVE_PATH := "user://battleboard_v03_save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_campaign(campaign: CampaignState,recruitment: RecruitmentManager,roster: RosterManager,training: TrainingManager,progression: ProgressionManager) -> bool:
	var profile_rows: Array = []
	for profile in roster.roster.values(): profile_rows.append((profile as BBProfile).to_dictionary())
	var data := {"version":3,"campaign":campaign.to_dictionary(),"profiles":profile_rows,"assignments":roster.assignments.duplicate(true),"training":training.to_dictionary(),"progression":progression.to_dictionary()}
	var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data,"  "))
	return true

func load_campaign(campaign: CampaignState,recruitment: RecruitmentManager,roster: RosterManager,training: TrainingManager,progression: ProgressionManager) -> bool:
	if not has_save(): return false
	var file := FileAccess.open(SAVE_PATH,FileAccess.READ)
	if file == null: return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version",0)) != 3: return false
	roster.clear()
	campaign.from_dictionary(parsed.get("campaign",{}))
	campaign.phase = "hq"
	for row in parsed.get("profiles",[]):
		var profile := BBProfile.from_dictionary(row)
		recruitment.import_recruited(profile)
		roster.add_profile(profile)
	for profile_id in parsed.get("assignments",{}).keys(): roster.assign(str(profile_id),str(parsed["assignments"][profile_id]))
	training.from_dictionary(parsed.get("training",{}))
	progression.from_dictionary(parsed.get("progression",{}))
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
