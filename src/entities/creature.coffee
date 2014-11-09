_ = require 'lodash'
Q = require 'q'

log = require '../log'
game = require '../game'

{bresenhamLine, arrayRemove, distanceSq} = require '../util'
direction = require '../direction'
RangedValue = require '../ranged-value'
vectorMath = require '../vector-math'

creatureSpecies = require '../definitions/creature-species'
items = require '../definitions/items'
calc = require '../calc'

{Entity} = require './entity'
MapItem = require './map-item'

module.exports = class Creature extends Entity
	symbol: -> @species?.symbol ? '§'
	type: 'creature'
	blocking: yes

	constructor: (m, x, y, @species, data = {}) ->
		super

		{
			@personalities
			@inventory, @equipment
			@xp, level
		} = data

		@species ?= new creatureSpecies.StrangeGoo

		@health ?= new RangedValue max: 30
		if @health? and not (@health instanceof RangedValue)
			@health = new RangedValue @health

		if level? and not @xp?
			@xp = calc.xpForLevel level

		@xp ?= 0

		Object.defineProperties @,
			level:
				get: => calc.levelFromXp @xp
				set: (level) =>
					@setXp calc.xpForLevel level

			weight:
				get: => @species.weight ? 0

		@personalities ?= []

		@inventory ?= []
		@equipment ?= {}

		@recalculateStats()

	isPlayer: ->
		@ is game.player.creature

	setXp: (xp) ->
		oldLvl = @level
		@xp = xp
		newLvl = @level

		if newLvl isnt oldLvl
			dlvl = newLvl - oldLvl

			@recalculateStats()
			game.emit 'game.creature.level-change', @, newLvl, oldLvl

	addXp: (dxp) ->
		@setXp @xp + dxp

	baseStat: (stat, params...) ->
		if stat in ['strength', 'endurance', 'agility']
			calc.creatureStat @, stat

		else if stat in [
			'health', 'attack', 'defense'
			'speed', 'accuracy'
			'weight', 'maxWeight'
		]
			calc.stat[stat] @, params...

	stat: (stat, params...) ->
		val = @baseStat stat, params...

		val = (@species.modifyStat? @, val, stat, params...) ? val
		for slot,item of @equipment
			val = (item.modifyStat? @, val, stat, slot, params...) ? val

		val

	@::calc = @::stat

	recalculateStats: ->
		percent = @health.percent
		@health.max = @stat 'health'
		@health.percent = percent

	overburdened: ->
		(calc.excessWeight this) > 0

	damage: (dmg, cause) ->
		game.emit 'game.creature.hurt', @, dmg, cause
		@health.current -= dmg

		@die cause if @health.empty()

	die: (cause) ->
		drop = (item) =>
			mapItem = new MapItem @map, @x, @y, item
			@map.addEntity mapItem
			game.timeManager.add mapItem

		if not @isPlayer()
			drop item for item in @inventory
			@inventory = []

			drop item for slot, item of @equipment
			@equipment = {}

			corpse = new items.Corpse @
			drop corpse

			@map.removeEntity @
			game.timeManager.remove @

		game.emit 'game.creature.dead', @, cause
		cause.level++ if cause.isPlayer?()

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

	throw: (item, offset) ->
		if _.isString offset
			offset = vectorMath.mult (direction.parse offset), 15

		endPos = vectorMath.add @, offset

		arrayRemove @inventory, item

		found = @raytraceUntilBlocked endPos, range: 15

		if found.type in ['creature', 'none']
			endPos = found

		else if found.type is 'wall'
			endPos = found.checked[1]

		game.renderer.doEffect
			type: 'line'
			start: @, end: endPos
			delay: 50
			symbol: _.result item, 'symbol'

		.then =>
			hit = no
			if found.type is 'creature'
				target = found.creature

				dealDamage = =>
					target.damage 5, @

				r = item.onHit? @map, endPos, target, dealDamage

				# if 'no' was returned, damage shouldn't be dealt
				if r isnt no
					dealDamage()
				
				hit = yes

			mapItem = new MapItem @map, endPos.x, endPos.y, item
			@map.addEntity mapItem
			game.timeManager.add mapItem
			
			item.onLand? @map, endPos, hit

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

	attack: (dir) ->
		{x, y} = direction.parse dir
		x += @x; y += @y

		if @map.collidable x, y
			# attacking a wall
			game.emit 'game.creature.attack.wall', @, dir

			@damage 3, 'attacking a wall'
			yes

		else
			creatures = @map.entitiesAt x, y, 'creature'
			if creatures.length > 0
				target = creatures[0]
				game.emit 'game.creature.attack.creature', @, dir, target

				item = @equipment['right hand']

				dmg = calc.meleeDamage @, item, target
				target.damage dmg, @
				yes

			else
				game.emit 'game.creature.attack.none', @, dir
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

	raytraceUntilBlocked: (to, opts = {}, cb) ->
		if _.isFunction opts then [opts, cb] = [{}, opts]
		opts.range ?= Infinity

		checked = []

		found = { type: 'none' }

		bresenhamLine @, to, (x, y) =>
			return no if (@distanceSqTo {x, y}) > (opts.range * opts.range)

			found.x = x
			found.y = y

			checked.unshift {x, y}
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

		found.checked = checked

		found

	collidable: (x, y) ->
		(@map.collidable x, y) or (@map.hasBlockingEntities x, y)

	tickRate: -> @calc 'speed'

	tick: (a...) ->
		Q(
			# check if this creature is controlled by player
			if @isPlayer() then game.player.tick a...

			else @aiTick a...
		)
		# .then (cost) ->
		# 	game.renderer.doEffects()

		# 	.thenResolve cost

	aiTick: ->
		# no personalities => brainless
		if @personalities.length is 0
			return @tickRate()

		# 0 is omitted because personalities with weight 0
		# shouldn't even be considered
		groups = _.omit (
			_.groupBy @personalities,
				(p) => (p.weight this) * (p.weightMultiplier ? 1)
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

	loadFromJSON: (json, defLoad) ->
		defLoad()

		@health = new RangedValue json.health

		@