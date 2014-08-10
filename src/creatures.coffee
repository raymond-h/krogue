Q = require 'q'
_ = require 'lodash'

{Entity} = require './entities'
direction = require './direction'

class exports.Creature extends Entity
	tick: (a...) ->
		# check if this creature is controlled by player
		if @ is (require './game').player.creature
			(require './game').player.tick a...

		else @aiTick a...

class exports.Dummy extends exports.Creature
	type: 'dummy'
	symbol: 'D'

	tickRate: 3

	aiTick: ->
		game = require './game'

		@move (game.random.sample _.values direction.directions)...

		12

class exports.FastDummy extends exports.Dummy
	type: 'fast-dummy'
	tickRate: 30

	symbol: 'F'

class exports.DummyWithPersonality extends exports.Creature
	type: 'dummy-with-personality'
	symbol: 'P'

	constructor: ->
		super
		@personality = new (require './personality').FleeFromPlayer 9

	tickRate: -> 11

	aiTick: ->
		w = @personality.weight(this)
		(require 'winston').info "Weight: #{w}"
		if w > 0 then @personality.tick(this)

		else @tickRate()

class exports.Human extends exports.Creature
	type: 'human'
	symbol: '@'

	constructor: (m, x, y, @name, @speed = 12) ->
		super

	tickRate: -> @speed

	aiTick: ->
		@tickRate()