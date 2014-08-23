game = require '../game'
personality = require '../personality'
{Creature} = require '../entities'
species = require '../creature-species'

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