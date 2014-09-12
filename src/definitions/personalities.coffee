Q = require 'q'

game = require '../game'

items = require './items'
direction = require '../direction'
vectorMath = require '../vector-math'

Personality = class exports.Personality
	constructor: ->
		@weightMultiplier = 1

	withMultiplier: (@weightMultiplier) -> this

	weight: (creature) -> 0

	tick: (creature) -> 0

class exports.FleeFromPlayer extends Personality
	constructor: (@safeDist) ->
		super

	weight: (creature) ->
		{distanceSq} = require '../util'
		if (
			(creature.canSee game.player.creature) and
			(creature.distanceSqTo game.player.creature) < (@safeDist*@safeDist)
		)
			100

		else 0

	tick: (creature) ->
		creature.moveAwayFrom game.player.creature

		12

class exports.RandomWalk extends Personality
	weight: (creature) ->
		100

	tick: (creature) ->
		direction = require '../direction'

		creature.move game.random.direction 8

		12

class exports.WantItems extends Personality
	constructor: (@range = 1, @wantedItems = null) ->

	weight: (creature) ->
		nearest = creature.findNearest @range, (e) ->
			e.type is 'item' and creature.canSee e

		if nearest? then 100 else 0

	tick: (creature) ->
		nearest = creature.findNearest @range, (e) ->
			e.type is 'item' and creature.canSee e

		creature.moveTo nearest

		itemsHere = creature.map.entitiesAt creature.x, creature.y, 'item'

		if itemsHere.length > 0
			item = itemsHere[0]
			creature.pickup item

		12

class exports.AttackAllButSpecies extends Personality
	constructor: (@species) ->

	locateTarget: (creature) ->
		creature.findNearest null, (e) =>
			e isnt creature and
			(e.type is 'creature') and
			(e.species.typeName isnt @species) and
			(creature.canSee e)

	weight: (creature) ->
		if (@locateTarget creature)? then 100 else 0

	tick: (creature) ->
		target = @locateTarget creature

		creature.moveTo target

		if Math.abs(creature.x - target.x) <= 1 and
				Math.abs(creature.y - target.y) <= 1

			creature.kick creature.directionTo target

		12

class exports.FleeIfWeak extends Personality
	weight: (creature) ->
		if creature.health.percent < 0.2 then 100 else 0

	tick: (creature) ->
		enemy = creature.findNearest 10, (e) -> e.type is 'creature'

		creature.moveAwayFrom enemy if enemy?

		12

class exports.Gunman extends Personality
	weight: (creature) ->
		if creature.equipment['right hand']?.fire?
			100
		else 0

	tick: (creature) ->
		gun = creature.equipment['right hand']
		range = gun.range

		target = creature.findNearest 30,
			(e) -> e.type is 'creature'

		if target?
			if (creature.distanceSqTo target) > range*range
				creature.moveTo target
				12

			else
				Q gun.fire creature, vectorMath.sub target, creature
				.thenResolve 6

		else 12

class exports.Kicker extends Personality
	constructor: (@range = 30) ->

	weight: (creature) ->
		target = creature.findNearest @range,
			(e) -> e.type is 'creature'

		if target? then 100 else 0

	tick: (creature) ->
		target = creature.findNearest @range,
			(e) -> e.type is 'creature'

		if target?
			if (
				Math.abs(creature.x - target.x) <= 1 and
				Math.abs(creature.y - target.y) <= 1
			)

				creature.kick creature.directionTo target

			else creature.moveTo target

		12