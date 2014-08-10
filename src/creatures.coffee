Q = require 'q'
_ = require 'lodash'

{Entity} = require './entities'
# direction = require './direction'

class exports.Creature extends Entity
	symbol: 'C'

	constructor: ->
		super

		@personality = new (require './personality').FleeFromPlayer 5

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
		if @personality.weight(this) > 0 then @personality.tick(this)

		else @tickRate()