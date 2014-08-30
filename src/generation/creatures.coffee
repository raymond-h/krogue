game = require '../game'
personality = require '../definitions/personalities'
species = require '../definitions/creature-species'
{Creature} = require '../entities'

itemGen = require './items'

exports.generateStrangeGoo = (x, y) ->
	c = new Creature null, x, y

	if game.random.chance 0.50
		c.speed = 30
		c.personalities.push [
			new personality.FleeFromPlayer 5
			(new personality.RandomWalk).withMultiplier 0.5
		]...

	else
		c.speed = 12
		c.personalities.push [
			new personality.FleeFromPlayer 5
			(new personality.WantItems 15).withMultiplier 0.5
		]...

	c

exports.generateViolentDonkey = (x, y) ->
	m = new Creature null, x, y, new species.ViolentDonkey
	m.speed = 8

	m.personalities.push [
		new personality.AttackAllButSpecies m.species.typeName
	]...

	m

exports.generateTinyAlien = (x, y) ->
	c = new Creature null, x, y, new species.TinyAlien
	c.speed = 10

	c.personalities.push [
		(new personality.FleeIfWeak).withMultiplier 10
		new personality.Kicker
	]...

	if game.random.chance 0.5
		c.equipment['right hand'] = itemGen.generateGun()

		c.personalities.push (new personality.Gunman).withMultiplier 2

	c