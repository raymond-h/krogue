_ = require 'lodash'
winston = require 'winston'

{arrayRemove} = require './util'

exports.fromJSON = (json) ->
	e = switch json.type
		when 'creature' then new Creature
		when 'item' then new MapItem

	e.loadFromJSON json
	e

Entity = class exports.Entity
	symbol: '-'

	constructor: (@map, @x, @y) ->

	setPos: (x, y) ->
		@x = x
		@y = y
		(require './game').renderer.invalidate()

	movePos: (x, y) ->
		@setPos @x+x, @y+y

	tickRate: 0

	tick: ->
	
	loadFromJSON: (json) ->
		_.assign @, _.omit json, 'type'
		@

	toJSON: ->
		o = _.pick @, (v, k, o) ->
			(_.has o, k) and not (k in ['map'])

		o.type = @type
		o

Creature = class exports.Creature extends Entity
	symbol: -> @species?.symbol ? '§'
	type: 'creature'

	constructor: (m, x, y, @species = null) ->
		super

		@species ?= new (require './creature-species').StrangeGoo
		@personalities = []

		@inventory = []

	isPlayer: ->
		@ is (require './game').player.creature

	pickup: (item) ->
		if item instanceof MapItem
			return if @pickup item.item
				arrayRemove @map.entities, item
				(require './game').timeManager.targets.remove item
				yes

			else no

		@inventory.push item
		yes

	drop: (item) ->
		return no if not (item? and item in @inventory)

		arrayRemove @inventory, item
		i = new MapItem @map, @x, @y, item
		@map.entities.push i
		(require './game').timeManager.targets.push i
		yes

	setPos: ->
		super

		game = require './game'
		game.camera.update() if @ is game.player.creature

	move: (x, y) ->
		canMoveThere = not @collidable @x+x, @y+y
		
		@movePos x, y if canMoveThere

		canMoveThere

	collidable: (x, y) ->
		(@map.collidable x, y) or
		(@map.entitiesAt x, y, 'creature').length > 0

	tickRate: -> @speed ? 12

	tick: (a...) ->
		game = require './game'
		
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

		personality = require './personality'
		creatureSpecies = require './creature-species'
		# because of how loadFromJSON() works in Entity,
		# @personalities and @species will be assigned their JSON reps.

		@species = creatureSpecies.fromJSON @species
		@personalities =
			personality.fromJSON p for p in @personalities

		@

MapItem = class exports.MapItem extends Entity
	symbol: -> @item.symbol
	type: 'item'

	constructor: (m, x, y, @item) ->
		super

	loadFromJSON: ->
		super

		items = require './items'

		@item = items.fromJSON @item

		@