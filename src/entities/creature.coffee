_ = require 'lodash'
RangedValue = require 'ranged-value'

log = require '../log'
game = require '../game'

{bresenhamLine, arrayRemove} = require '../util'
{p} = require '../util'
direction = require '../direction'
vectorMath = require '../vector-math'
pathFinding = require '../path-finding'

creatureSpecies = require '../definitions/creature-species'
items = require '../definitions/items'
buffs = require '../definitions/buffs'
calc = require '../calc'

{Entity, MapItem} = require './entity'

module.exports = class Creature extends Entity
	type: 'creature'
	blocking: yes

	constructor: (m, x, y, @species, data = {}) ->
		super

		{
			@personalities
			@inventory, @equipment
			@xp, level
		} = data

		@species ?= creatureSpecies.strangeGoo

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
		@equipment ?= []

		@buffs ?= []

		@_skills ?= []

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
		for item in @equipment
			val = (item.modifyStat? @, val, stat, slot, params...) ? val
		for buff in @buffs
			val = (item.modifyStat? @, val, stat, params...) ? val

		val

	@::calc = @::stat

	recalculateStats: ->
		percent = @health.percent
		@health.max = @stat 'health'
		@health.percent = percent

	skills: ->
		[
			@species.skills(this)...
			@_skills...
		]

	skill: (name) ->
		_.find @skills(), (skill) -> skill.name is name

	overburdened: ->
		(calc.excessWeight this) > 0

	equipSlotCount: (slot) ->
		@equipment
		.map (item) => item.getEquipSlotUse slot, @
		.reduce ((prev, curr) -> prev + curr), 0

	maxSpacesInSlot: (slot) ->
		@species.equipSlotNum[slot]

	equipSlotFits: (slot, item) ->
		maxSpaces = @maxSpacesInSlot slot

		((@equipSlotCount slot) + (item.getEquipSlotUse slot, @)) <= maxSpaces

	hasItemEquipped: (item) ->
		item in @equipment

	hasItemInSlot: (slot, extraCheck) ->
		_.any @equipment, (item) =>
			(item.getEquipSlotUse slot, @) > 0 and (extraCheck?(item, slot) ? yes)

	getItemsForSlot: (slot) ->
		@equipment.filter (item) => (item.getEquipSlotUse slot, @) > 0

	belongsToGroup: (other) ->
		if _.isString other
			return @group? and @group is other

		@group? and other.group? and @group is other.group

	isGroupLeader: (other) ->
		@leader? and @belongsToGroup other

	damage: (dmg, cause) ->
		game.emit 'game.creature.hurt', @, dmg, cause
		@health.current -= dmg

		@die cause if @health.empty

	die: (cause) ->
		drop = (item) =>
			mapItem = item.asMapItem @x, @y
			@map.addEntity mapItem
			game.timeManager.add mapItem

		if not @isPlayer()
			drop item for item in @inventory
			@inventory = []

			drop item for item in @equipment
			@equipment = []

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

				yes

			else no

		@inventory.push item
		game.emit 'game.creature.pickup', @, item
		yes

	drop: (item) ->
		return no if not (item? and item in @inventory)

		arrayRemove @inventory, item

		mapItem = item.asMapItem @x, @y
		@map.addEntity mapItem
		game.timeManager.add mapItem

		game.emit 'game.creature.drop', @, item
		yes

	equip: (item, silent = no) ->
		notFit = (slot) =>
			not @equipSlotFits slot, item

		if _.any creatureSpecies._equipSlots, notFit
			return no

		arrayRemove @inventory, item
		@equipment.push item
		if not silent then game.emit 'game.creature.equip', @, item
		yes

	unequip: (item, silent = no) ->
		log.info "Is it equipped already? #{@hasItemEquipped item}"

		if @hasItemEquipped item
			arrayRemove @equipment, item
			@inventory.push item
			game.emit 'game.creature.unequip', @, item
			yes

		else no

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

		game.effects.throw
			item: item
			start: @, end: endPos

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

			mapItem = item.asMapItem endPos.x, endPos.y
			@map.addEntity mapItem
			game.timeManager.add mapItem

			item.onLand? @map, endPos, hit

	move: (x, y) ->
		if _.isString x then x = direction.parse x
		if _.isObject x then {x, y} = x

		canMoveThere = not @collidable @x+x, @y+y

		@movePos x, y if canMoveThere

		canMoveThere

	moveTo: (p, pathfind = no) ->
		if not pathfind
			@move @directionTo p

		else
			{status, path} = pathFinding.aStarOverDistanceMap @map, @, p

			if status is 'success'
				@move vectorMath.sub path[1], @

			else no

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

				item = game.random.sample @getItemsForSlot 'hand'

				dmg = calc.meleeDamage @, item, target
				target.damage dmg, @
				yes

			else
				game.emit 'game.creature.attack.none', @, dir
				no

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
		@buffs = json.buffs
			.map (json) -> buffs.fromJSON json

		@
