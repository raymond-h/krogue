_ = require 'lodash'

meleeDamage = (attacker, item, target) ->
	attack(attacker, item) - defense(target)

attack = (attacker, item) ->
	attacker.strength + (item?.damage ? 0)

defense = (defender) ->
	totalArmor =
		_.chain defender.equipment
		.pluck 'armor'
		.reduce ( (sum, v) -> sum + (v ? 0) ), 0
		.value()

	defender.defense + totalArmor

module.exports = {
	meleeDamage, attack, defense
}