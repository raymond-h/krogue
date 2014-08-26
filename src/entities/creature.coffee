_ = require 'lodash'
winston = require 'winston'

game = require '../game'
{bresenhamLine, arrayRemove, distanceSq} = require '../util'
direction = require '../direction'
RangedValue = require '../ranged-value'

{Entity} = require './entity'
MapItem = require './map-item'

module.exports = class Creature extends Entity
	symbol: -> @species?.symbol ? '§'
	type: 'creature'
	blocking: yes

	constructor: (m, x, y, @species = null) ->
		super

		@health = new RangedValue max: 30

		@species ?= new (require '../creature-species').StrangeGoo
		@personalities = []

		@inventory = []
		@equipment = {}

	isPlayer: ->
		@ is game.player.creature

	damage: (dmg, cause) ->
		game.emit 'game.creature.hurt', @, dmg, cause
		@health.current -= dmg

		@die cause if @health.empty()

	die: (cause) ->
		if not @isPlayer()
			for item in @inventory
				mapItem = new MapItem @map, @x, @y, item
				@map.addEntity mapItem
				game.timeManager.add mapItem

			@map.removeEntity @
			game.timeManager.remove @

		game.emit 'game.creature.dead', @, cause

	pickup: (item) ->
		if item instanceof MapItem
			return if @pickup item.item
				@map.removeEntity item
				game.timeManager.remove item

				game.renderer.invalidate()
				yes

			else no

		@inventory.push item
		game.emit 'game.creature.pickup', @, item
		yes

	drop: (item) ->
		return no if not (item? and item in @inventory)

		arrayRemove @inventory, item

		mapItem = new MapItem @map, @x, @y, item
		@map.addEntity mapItem
		game.timeManager.add mapItem

		game.emit 'game.creature.drop', @, item
		game.renderer.invalidate()
		yes

	equip: (slot, item) ->
		return no if not (slot in @species.equipSlots)
		return no if not (item in @inventory)

		(@unequip slot) if @equipment[slot]?

		arrayRemove @inventory, item
		@equipment[slot] = item
		game.emit 'game.creature.equip', @, slot, item
		yes

	unequip: (item) ->
		if _.isString item
			[slot, item] = [item, @equipment[item]]

		else
			break for slot, i of @equipment when i is item

		if not (slot? or item?) or @equipment[slot] isnt item then no
		else
			delete @equipment[slot]
			@inventory.push item
			game.emit 'game.creature.unequip', @, slot, item
			yes

	setPos: ->
		super
		game.camera.update() if @ is game.player.creature

	move: (x, y) ->
		if _.isString x then x = direction.parse x
		if _.isObject x then {x, y} = x

		canMoveThere = not @collidable @x+x, @y+y
		
		@movePos x, y if canMoveThere

		canMoveThere

	moveTo: (p) ->
		@move @directionTo p

	moveAwayFrom: (p) ->
		@move direction.opposite @directionTo p

	kick: (dir) ->
		{x, y} = direction.parse dir
		x += @x; y += @y

		if @map.collidable x, y
			# kicking a wall
			game.emit 'game.creature.kick.wall', @, dir

			@damage 3, 'kicking a wall'
			yes

		else
			creatures = @map.entitiesAt x, y, 'creature'
			if creatures.length > 0
				target = creatures[0]
				game.emit 'game.creature.kick.creature', @, dir, target
				target.damage 2, @
				yes

			else
				game.emit 'game.creature.kick.none', @, dir
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

		for e in @map.entities when not (e is @) and cb e
			dSq = @distanceSqTo e

			if dSq < minDist
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
		(@map.collidable x, y) or (@map.hasBlockingEntities x, y)

	tickRate: -> @speed ? 12

	tick: (a...) ->
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
		# fields with class instances will be assigned their JSON reps.

		@health = new RangedValue @health

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