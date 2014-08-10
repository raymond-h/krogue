Q = require 'q'
_ = require 'lodash'

{Entity} = require './entities'
# direction = require './direction'

class exports.Creature extends Entity
	symbol: 'C'

	constructor: ->
		super

		@personalities = []

	setPos: ->
		super

		game = require './game'
		game.camera.update() if @ is game.player.creature

	tickRate: -> @speed ? 12

	tick: (a...) ->
		game = require './game'
		
		# check if this creature is controlled by player
		if @ is game.player.creature
			game.player.tick a...

		else @aiTick a...

	aiTick: ->
		# no personalities => brainless
		if @personalities.length is 0
			return @tickRate()

		# 0 is omitted because personalities with weight 0
		# shouldn't even be considered
		groups = _.omit (
			_.groupBy @personalities, (p) => p.weight this
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
		# because of how loadFromJSON() works in Entity,
		# @personalities will be assigned the JSON repr.
		# of each personality

		@personalities =
			personality.fromJSON p for p in @personalities