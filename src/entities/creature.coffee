_ = require 'lodash'
winston = require 'winston'

{bresenhamLine, arrayRemove, distanceSq} = require '../util'
direction = require '../direction'

{Entity} = require './entity'
MapItem = require './map-item'

module.exports = class Creature extends Entity
	symbol: -> @species?.symbol ? '§'
	type: 'creature'

	constructor: (m, x, y, @species = null) ->
		super

		@species ?= new (require '../creature-species').StrangeGoo
		@personalities = []

		@inventory = []
		@equipment = {}

	isPlayer: ->
		@ is (require '../game').player.creature

	pickup: (item) ->
		game = require '../game'

		if item instanceof MapItem
			return if @pickup item.item
				arrayRemove @map.entities, item
				game.timeManager.targets.remove item
				game.renderer.invalidate()
				yes

			else no

		@inventory.push item
		yes

	drop: (item) ->
		return no if not (item? and item in @inventory)

		game = require '../game'

		arrayRemove @inventory, item
		i = new MapItem @map, @x, @y, item
		@map.entities.push i
		game.timeManager.targets.push i
		game.renderer.invalidate()
		yes

	setPos: ->
		super

		game = require '../game'
		game.camera.update() if @ is game.player.creature

	move: (x, y) ->
		canMoveThere = not @collidable @x+x, @y+y
		
		@movePos x, y if canMoveThere

		canMoveThere

	kick: (dir) ->
		game = require '../game'

		[x, y] = direction.parse dir
		x += @x; y += @y

		if @map.collidable x, y
			# kicking a wall
			game.message "You kick a wall! Luckily, your suit protects you."
			yes

		else
			creatures = @map.entitiesAt x, y, 'creature'
			if creatures.length > 0
				target = creatures[0]
				game.message "You kick at the #{target.species.name}!"
				yes

			else
				game.message "You do a cool kick without hitting anything!"
				no

	distanceSqTo: (to) ->
		distanceSq @, to

	distanceTo: (to) ->
		Math.sqrt @distanceSqTo to

	inRange: (range, to) ->
		(@distanceSqTo to) <= (range*range)

	directionTo: (to) ->
		direction.getDirection @, to

	findNearest: (maxRange = Infinity, cb) ->
		minDist = maxRange * maxRange
		nearest = null

		for e in @map.entities when cb e
			dSq = @distanceSqTo e

			if dSq < minDist*minDist
				[minDist, nearest] = [dSq, e]

		nearest

	canSee: (to) ->
		visible = yes

		bresenhamLine @, to, (x, y) =>
			return if x is to.x and y is to.y

			if not @map.seeThrough x, y then visible = no

		visible

	raytraceUntilBlocked: (to, cb) ->
		found = { type: 'none' }

		bresenhamLine @, to, (x, y) =>
			return if x is @x and y is @y

			if @map.collidable x, y
				found = {
					type: 'wall'
					x, y
				}
				return no

			creatures = @map.entitiesAt x, y, 'creature'
			if creatures.length > 0
				found = {
					type: 'creature'
					creature: creatures[0]
					x, y
				}
				return no

		found

	collidable: (x, y) ->
		(@map.collidable x, y) or
		(@map.entitiesAt x, y, 'creature').length > 0

	tickRate: -> @speed ? 12

	tick: (a...) ->
		game = require '../game'
		
		# check if this creature is controlled by player
		if @isPlayer() then game.player.tick a...

		else @aiTick a...

	aiTick: ->
		# no personalities => brainless
		if @personalities.length is 0
			return @tickRate()

		# 0 is omitted because personalities with weight 0
		# shouldn't even be considered
		groups = _.omit (
			_.groupBy @personalities,
				(p) => (p.weight this) * p.weightMultiplier
		), '0'

		weights = _.keys groups

		# no potential choices => indifferent
		if weights.length is 0
			return @tickRate()

		choices = groups[Math.max weights...]

		# 2 or more choices => indecisive
		if choices.length >= 2
			return @tickRate()

		choices[0].tick this

	loadFromJSON: ->
		super

		personality = require '../personality'
		creatureSpecies = require '../creature-species'
		items = require '../items'
		# because of how loadFromJSON() works in Entity,
		# @personalities and @species will be assigned their JSON reps.

		@species = creatureSpecies.fromJSON @species
		@personalities =
			personality.fromJSON p for p in @personalities
		@inventory =
			items.fromJSON i for i in @inventory

		@equipment =
			_.zipObject (
				[s, items.fromJSON i] for s,i of @equipment
			)

		@