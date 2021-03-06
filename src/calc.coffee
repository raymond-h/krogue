_ = require 'lodash'

random = require './random'

meleeDamage = (subject, item, target) ->
	dmgDev = (-0.1107 * (subject.calc 'accuracy', item) + 3.32881) * 4

	[meleeDmg] = random.gaussian (subject.calc 'attack', item), dmgDev
	dmg = Math.round meleeDmg - (target.calc 'defense')

	Math.max 0, dmg

gunDamage = (subject, gun, target) ->
	dmgDev = (-0.1107 * (subject.calc 'accuracy', gun) + 3.32881) * 4

	[gunDmg] = random.gaussian gun.damage, dmgDev
	dmg = Math.round gunDmg - (target.calc 'defense')

	Math.max 0, dmg

xpForLevel = (level) ->
	(level-1) * 100

levelFromXp = _.memoize (xp) ->
	level = 1
	while (xpForLevel level+1) <= xp
		level++
	level

itemSlotUse = (creature, item) ->
	cs = creature.calc 'strength'
	iw = item.weight ? 0

	# Math.max 1, Math.ceil (iw * 5) / cs
	Math.max 1, Math.round(
		0.148773 * iw * Math.pow Math.E, -0.0241275 * (cs - 15) / 3
	)

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
				subject.equipment
				.map (item) -> weightOf item
				.reduce ((p, c) -> p+c), 0

			else 0

		subjWeight = if itself then weightOf subject else 0

		subjWeight + eqpWeight + invWeight

	excessWeight: (subject) ->
		Math.max 0, (subject.calc 'weight', itself: no) - (subject.calc 'maxWeight')

module.exports = {
	meleeDamage, gunDamage
	itemSlotUse
	xpForLevel, levelFromXp
	creatureStat

	stat
}
