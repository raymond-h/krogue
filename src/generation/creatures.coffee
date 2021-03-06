random = require '../random'
personality = require '../definitions/personalities'
species = require '../definitions/creature-species'
items = require '../definitions/items'
{Creature} = require '../entities'

itemGen = require './items'

exports.generateStartingPlayer = (x, y) ->
	c = new Creature {x, y, species: species.human}

	gun = itemGen.generateStartingGun()

	c.equip gun, yes

	c.inventory = for i in [1..5]
		new items.PokeBall random.sample ['normal', 'great', 'ultra', 'master']

	c.inventory.push new items.BulletPack (new items.Bullet 'medium'), 20
	c.inventory.push new items.BulletPack (new items.Bullet 'medium'), 5

	c

exports.generateStrangeGoo = (x, y) ->
	c = new Creature {x, y}

	if random.chance 0.50
		c.personalities.push [
			new personality.FleeFromPlayer c, 5
			(new personality.RandomWalk c).withMultiplier 0.5
		]...

	else
		c.personalities.push [
			new personality.FleeFromPlayer c, 5
			(new personality.WantItems c, 15).withMultiplier 0.5
		]...

	c

exports.generateViolentDonkey = (x, y) ->
	c = new Creature {x, y, species: species.violentDonkey}

	c.personalities.push [
		new personality.AttackAllButSpecies c, c.species.typeName
	]...

	c

exports.generateTinyAlien = (x, y) ->
	c = new Creature {x, y, species: species.tinyAlien}

	c.personalities.push [
		(new personality.FleeIfWeak c).withMultiplier 10
		new personality.Attacker c
	]...

	if random.chance 0.5
		c.equip itemGen.generateGun()

		c.personalities.push (new personality.Gunman c).withMultiplier 2

	c

exports.generateSpaceAnemone = (x, y) ->
	c = new Creature {x, y, species: species.spaceAnemone}

	c.personalities.push [
		new personality.RandomWalk c
		(new personality.Attacker c, 6).withMultiplier 2
	]...

	c

exports.generateSpaceBee = (x, y, {monarch, group} = {}) ->
	monarch ?= no
	group ?= null

	c = new Creature {
		x, y,
		species:
			if monarch then species.spaceBeeMonarch
			else species.spaceBee
	}

	c.group = group

	if not monarch
		c.personalities.push [
			(new personality.NoLeaderOutrage c, 20).withMultiplier 10
			(new personality.FendOffFromLeader c).withMultiplier 6
			(new personality.HateOpposingBees c).withMultiplier 3
			new personality.RandomWalk c
		]...

	else
		c.leader = yes

		c.personalities.push [
			new personality.RandomWalk c, 0.2
		]...

	c

exports.generateHaithera = (x, y) ->
	c = new Creature {x, y, species: species.haithera}

	c.personalities.push [
		(new personality.Attacker c, 10).withMultiplier 2
		new personality.RandomWalk c
	]...

	c
