extends Node

const LEVEL_CAP = 99
const EXPERIENCE_CAP = 200000000  # 200M (OSRS actual cap, though 99 is ~13M)
const EXPERIENCE_FOR_99 = 13034431

# OSRS uses this exact formula for experience tables
static func get_experience_for_level(level: int) -> int:
	if level < 1:
		return 0
	if level >= LEVEL_CAP:
		return EXPERIENCE_FOR_99
	
	var total_xp = 0
	for lvl in range(1, level):
		total_xp += int(floor(lvl + 300.0 * pow(2.0, lvl / 7.0)))
	
	return int(floor(total_xp / 4.0))

static func get_level_from_experience(experience: int) -> int:
	if experience < 1:
		return 1
	if experience >= EXPERIENCE_FOR_99:
		return LEVEL_CAP
	
	# Binary search through levels for efficiency
	for level in range(1, LEVEL_CAP + 1):
		if get_experience_for_level(level + 1) > experience:
			return level
	
	return LEVEL_CAP

static func get_experience_needed(current_experience: int) -> int:
	var current_level = get_level_from_experience(current_experience)
	
	if current_level >= LEVEL_CAP:
		return 0
	
	var next_level_xp = get_experience_for_level(current_level + 1)
	return next_level_xp - current_experience

static func get_level_progress(current_experience: int) -> float:
	var current_level = get_level_from_experience(current_experience)
	
	if current_level >= LEVEL_CAP:
		return 1.0
	
	var current_level_xp = get_experience_for_level(current_level)
	var next_level_xp = get_experience_for_level(current_level + 1)
	var xp_into_level = current_experience - current_level_xp
	var xp_needed = next_level_xp - current_level_xp
	
	return float(xp_into_level) / float(xp_needed)
