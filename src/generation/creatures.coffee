game = require '../game'
personality = require '../definitions/personalities'
species = require '../definitions/creature-species'
{Creature} = require '../entities'

itemGen = require './items'

exports.generateStrangeGoo = (x, y) ->
	c = new Creature null, x, y

	if game.random.chance 0.50
		c.personalities.push [
			new personality.FleeFromPlayer 5
			(new personality.RandomWalk).withMultiplier 0.5
		]...

	else
		c.personalities.push [
			new personality.FleeFromPlayer 5
			(new personality.WantItems 15).withMultiplier 0.5
		]...

	c

exports.generateViolentDonkey = (x, y) ->
	m = new Creature null, x, y, species.violentDonkey

	m.personalities.push [
		new personality.AttackAllButSpecies m.species.typeName
	]...

	m

exports.generateTinyAlien = (x, y) ->
	c = new Creature null, x, y, species.tinyAlien

	c.personalities.push [
		(new personality.FleeIfWeak).withMultiplier 10
		new personality.Attacker
	]...

	if game.random.chance 0.5
		c.equip itemGen.generateGun()

		c.personalities.push (new personality.Gunman).withMultiplier 2

	c

exports.generateSpaceAnemone = (x, y) ->
	c = new Creature null, x, y, species.spaceAnemone

	c.personalities.push [
		new personality.RandomWalk
		(new personality.Attacker 6).withMultiplier 2
	]...

	c

exports.generateSpaceBee = (x, y, {monarch, group} = {}) ->
	monarch ?= no
	group ?= null

	c = new Creature null, x, y,
		if monarch then species.spaceBeeMonarch
		else species.spaceBee

	c.group = group

	if not monarch
		c.personalities.push [
			(new personality.NoLeaderOutrage 20).withMultiplier 10
			(new personality.FendOffFromLeader).withMultiplier 6
			(new personality.HateOpposingBees).withMultiplier 3
			new personality.RandomWalk
		]...

	else
		c.leader = yes

		c.personalities.push [
			new personality.RandomWalk 0.2
		]...

	c