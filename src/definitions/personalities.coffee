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
	constructor: (@probability = 1) ->

	weight: (creature) ->
		100

	tick: (creature) ->
		direction = require '../direction'

		creature.move game.random.direction 8 if game.random.chance @probability

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

			creature.attack creature.directionTo target

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
		if creature.hasItemInSlot 'hand', ((item) -> item.fire?)
			100

		else 0

	tick: (creature) ->
		gun = game.random.sample creature.getItemsForSlot 'hand'

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

class exports.Attacker extends Personality
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

				creature.attack creature.directionTo target

			else creature.moveTo target

		12

class exports.NoLeaderOutrage extends Personality
	constructor: (@range = 12) ->
		Object.defineProperty @, 'target',
			enumerable: no
			writable: yes

		Object.defineProperty @, 'monarch',
			enumerable: no
			writable: yes

	weight: (creature) ->
		[@monarch] = creature.map.listEntities (e) ->
			e.type is 'creature' and
			e.group is creature.group and
			e.leader

		if not @monarch? then 100 else 0

	tick: (creature) ->
		@target = creature.findNearest @range,
			(e) ->
				e.type is 'creature' and (
					e.group isnt creature.group
				)

		if @target?
			if (
				Math.abs(creature.x - @target.x) <= 1 and
				Math.abs(creature.y - @target.y) <= 1
			)

				creature.attack creature.directionTo @target

			else creature.moveTo @target

		else
			direction = require '../direction'

			creature.move game.random.direction 8

		4

class exports.HateOpposingBees extends Personality
	constructor: (@range = 12) ->
		Object.defineProperty @, 'target',
			enumerable: no
			writable: yes

	weight: (creature) ->
		@target = creature.findNearest @range,
			(e) ->
				e.type is 'creature' and
				e.species is creature.species and
				e.group isnt creature.group

		if @target? then 100 else 0

	tick: (creature) ->
		# target is guaranteed to exist

		if (
			Math.abs(creature.x - @target.x) <= 1 and
			Math.abs(creature.y - @target.y) <= 1
		)

			creature.attack creature.directionTo @target

		else creature.moveTo @target

		12

class exports.FendOffFromLeader extends Personality
	constructor: (@range = 6) ->
		Object.defineProperty @, 'target',
			enumerable: no
			writable: yes

		Object.defineProperty @, 'monarch',
			enumerable: no
			writable: yes

	weight: (creature) ->
		weight = do =>
			[@monarch] = creature.map.listEntities (e) ->
				e.type is 'creature' and
				e.group is creature.group and
				e.leader?

			return 0 if not @monarch?

			@target = @monarch.findNearest @range,
				(e) =>
					e.type is 'creature' and
					(not e.group? or e.group isnt @monarch.group)

			if @target? then 100 else 0

		weight

	tick: (creature) ->
		# target is guaranteed to exist

		if (
			Math.abs(creature.x - @target.x) <= 1 and
			Math.abs(creature.y - @target.y) <= 1
		)

			creature.attack creature.directionTo @target

		else
			pathFinding = require '../path-finding'

			{status, path: [start, next]} =
				pathFinding.aStar creature.map, creature, @target

			creature.move vectorMath.sub next, creature

		12