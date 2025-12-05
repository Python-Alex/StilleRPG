extends Node

var experience : float = 0.00

var _skill_structure = {
	SkillManager.SkillTypes.ATTACK: 1,
	SkillManager.SkillTypes.STRENGTH: 1,
	SkillManager.SkillTypes.DEFENCE: 1,
	SkillManager.SkillTypes.HITPOINTS: 1,
	SkillManager.SkillTypes.ENDURANCE: 1,
	SkillManager.SkillTypes.FARMING: 1,
	SkillManager.SkillTypes.CRAFTING: 1,
	SkillManager.SkillTypes.WOODCUTTING: 1,
}

func get_total_experience() -> float:
	var total = 0.0
	for skill_xp in _skill_structure.values():
		total += skill_xp
	return total
