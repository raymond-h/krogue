_ = require 'lodash'

meleeDamage = (subject, item, target) ->
	Math.floor (subject.calc 'attack', item) - (target.calc 'defense')

xpForLevel = (level) ->
	(level-1) * 100

levelFromXp = _.memoize (xp) ->
	level = 1
	while (xpForLevel level+1) <= xp
		level++
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
		Math.max 1, (subject.calc 'agility') / 3 - stat.excessWeight subject

	accuracy: (subject, {accuracy} = {}) ->
		((subject.calc 'strength') + (subject.calc 'agility')) * (accuracy ? 1)

	maxWeight: (subject) ->
		subject.calc 'strength'

	## Intermediate calculations
	weight: (subject, include = {}) ->
		_.defaults include,
			{ itself: yes, inventory: yes, equips: yes }

		{itself, inventory, equips} = include

		weightOf = (i) -> i.weight ? 0

		invWeight =
			if inventory
				subject.inventory
				.map (item) -> weightOf item
				.reduce ((p, c) -> p+c), 0

			else 0

		eqpWeight =
			if equips
				(weightOf item for slot,item of subject.equipment)
				.reduce ((p, c) -> p+c), 0

			else 0

		subjWeight = if itself then weightOf subject else 0

		subjWeight + eqpWeight + invWeight

	excessWeight: (subject) ->
		Math.max 0, (subject.calc 'weight', itself: no) - (subject.calc 'maxWeight')

module.exports = {
	meleeDamage
	xpForLevel, levelFromXp
	creatureStat

	stat
}