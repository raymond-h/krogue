_ = require 'lodash'
winston = require 'winston'

meleeDamage = (subject, item, target) ->
	Math.floor (subject.calc 'attack', item) - (target.calc 'defense')

xpForLevel = (level) ->
	level * 100

levelFromXp = _.memoize (xp) ->
	level = 1
	level++ while (xp -= xpForLevel level) >= 0
	level

creatureStat = (creature, stat) ->
	15 + 3 * creature.level

## Stat calculations
stat =
	health: (subject) ->
		subject.calc 'endurance'

	attack: (subject, {damage} = {}) ->
		(subject.calc 'strength') + (damage ? 0)

	defense: (subject) ->
		totalArmor =
			_.chain subject.equipment
			.pluck 'armor'
			.reduce ( (sum, v) -> sum + (v ? 0) ), 0
			.value()

		(subject.calc 'endurance') / 3 + totalArmor

	speed: (subject) ->
		(subject.calc 'agility') / 3 - stat.excessWeight subject

	accuracy: (subject, {accuracy} = {}) ->
		((subject.calc 'strength') + (subject.calc 'agility')) * (accuracy ? 1)

	maxWeight: (subject) ->
		subject.calc 'strength'

	## Intermediate calculations
	weight: (subject) ->
		0

	excessWeight: (subject) ->
		Math.max 0, (subject.calc 'weight') - (subject.calc 'maxWeight')

module.exports = {
	meleeDamage
	xpForLevel, levelFromXp
	creatureStat

	stat
}