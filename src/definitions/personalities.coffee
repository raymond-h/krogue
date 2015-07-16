_ = require 'lodash'

game = require '../game'

items = require './items'
direction = require '../direction'
vectorMath = require '../vector-math'
{p} = require '../util'

Personality = class exports.Personality
	constructor: (@creature) ->
		@weightMultiplier = 1

	withMultiplier: (@weightMultiplier) -> this

	weight: -> 0

	tick: -> 0

	toJSON: ->
		_.omit @, 'creature'

class exports.FleeFromPlayer extends Personality
	constructor: (c, @safeDist) ->
		super

	weight: ->
		{distanceSq} = require '../util'
		if (
			(@creature.canSee game.player.creature) and
			(@creature.distanceSqTo game.player.creature) < (@safeDist*@safeDist)
		)
			100

		else 0

	tick: ->
		@creature.moveAwayFrom game.player.creature

		12

class exports.RandomWalk extends Personality
	constructor: (c, @probability = 1) ->
		super

	weight: ->
		100

	tick: ->
		direction = require '../direction'

		@creature.move game.random.direction 8 if game.random.chance @probability

		12

class exports.WantItems extends Personality
	constructor: (c, @range = 1, @wantedItems = null) ->
		super

	weight: ->
		nearest = @creature.findNearest @range, (e) =>
			e.type is 'item' and @creature.canSee e

		if nearest? then 100 else 0

	tick: ->
		nearest = @creature.findNearest @range, (e) =>
			e.type is 'item' and @creature.canSee e

		@creature.moveTo nearest

		itemsHere = @creature.map.entitiesAt @creature.x, @creature.y, 'item'

		if itemsHere.length > 0
			item = itemsHere[0]
			@creature.pickup item

		12

class exports.AttackAllButSpecies extends Personality
	constructor: (c, @species) ->
		super

	locateTarget: ->
		@creature.findNearest null, (e) =>
			e isnt @creature and
			(e.type is 'creature') and
			(e.species.typeName isnt @species) and
			(@creature.canSee e)

	weight: ->
		if (@locateTarget @creature)? then 100 else 0

	tick: ->
		target = @locateTarget @creature

		@creature.moveTo target

		if Math.abs(@creature.x - target.x) <= 1 and
				Math.abs(@creature.y - target.y) <= 1

			@creature.attack @creature.directionTo target

		12

class exports.FleeIfWeak extends Personality
	weight: ->
		if @creature.health.percent < 0.2 then 100 else 0

	tick: ->
		enemy = @creature.findNearest 10, (e) -> e.type is 'creature'

		@creature.moveAwayFrom enemy if enemy?

		12

class exports.Gunman extends Personality
	weight: ->
		if @creature.hasItemInSlot 'hand', ((item) -> item.fire?)
			100

		else 0

	tick: ->
		gun = game.random.sample @creature.getItemsForSlot 'hand'

		range = gun.range

		target = @creature.findNearest 30,
			(e) -> e.type is 'creature'

		if target?
			if (@creature.distanceSqTo target) > range*range
				@creature.moveTo target
				12

			else
				p gun.fire @creature, vectorMath.sub target, @creature
				.then -> 6

		else 12

class exports.Attacker extends Personality
	constructor: (c, @range = 30) ->
		super

	weight: ->
		target = @creature.findNearest @range,
			(e) -> e.type is 'creature'

		if target? then 100 else 0

	tick: ->
		target = @creature.findNearest @range,
			(e) -> e.type is 'creature'

		if target?
			if (
				Math.abs(@creature.x - target.x) <= 1 and
				Math.abs(@creature.y - target.y) <= 1
			)

				@creature.attack @creature.directionTo target

			else @creature.moveTo target

		12

class exports.NoLeaderOutrage extends Personality
	constructor: (c, @range = 12) ->
		super

		Object.defineProperty @, 'target',
			enumerable: no
			writable: yes

		Object.defineProperty @, 'monarch',
			enumerable: no
			writable: yes

	weight: ->
		[@monarch] = @creature.map.listEntities (e) =>
			e.type is 'creature' and e.isGroupLeader @creature

		if not @monarch? then 100 else 0

	tick: ->
		@target = @creature.findNearest @range, (e) =>
			e.type is 'creature' and not e.belongsToGroup @creature

		if @target?
			if (
				Math.abs(@creature.x - @target.x) <= 1 and
				Math.abs(@creature.y - @target.y) <= 1
			)

				@creature.attack @creature.directionTo @target

			else @creature.moveTo @target

		else
			direction = require '../direction'

			@creature.move game.random.direction 8

		4

class exports.HateOpposingBees extends Personality
	constructor: (c, @range = 12) ->
		super

		Object.defineProperty @, 'target',
			enumerable: no
			writable: yes

	weight: ->
		@target = @creature.findNearest @range,
			(e) =>
				e.type is 'creature' and
				e.species is @creature.species and
				not e.belongsToGroup @creature

		if @target? then 100 else 0

	tick: ->
		# target is guaranteed to exist

		if (
			Math.abs(@creature.x - @target.x) <= 1 and
			Math.abs(@creature.y - @target.y) <= 1
		)

			@creature.attack @creature.directionTo @target

		else @creature.moveTo @target

		12

class exports.FendOffFromLeader extends Personality
	constructor: (c, @range = 6) ->
		super

		Object.defineProperty @, 'target',
			enumerable: no
			writable: yes

		Object.defineProperty @, 'monarch',
			enumerable: no
			writable: yes

	weight: ->
		weight = do =>
			[@monarch] = @creature.map.listEntities (e) =>
				e.type is 'creature' and e.isGroupLeader @creature

			return 0 if not @monarch?

			@target = @monarch.findNearest @range,
				(e) =>
					e.type is 'creature' and not e.belongsToGroup @creature

			if @target? then 100 else 0

		weight

	tick: ->
		# target is guaranteed to exist

		if (
			Math.abs(@creature.x - @target.x) <= 1 and
			Math.abs(@creature.y - @target.y) <= 1
		)

			@creature.attack @creature.directionTo @target

		else
			@creature.moveTo @target, yes

		12