Q = require 'q'

{Entity} = require './entities'

class exports.Creature extends Entity

class exports.Dummy extends exports.Creature
	tickRate: 10

	tick: ->
		# console.log 'Rock on, you dick'

		Q.delay 1000
		# .then -> console.log 'Depleted resources, must wait...'
		.thenResolve 30

class exports.Player extends exports.Creature
	constructor: (g, m, x, y, @name, @speed = 12) ->
		super

		@symbol = '@'

	tickRate: -> @speed

	tick: ->
		# console.log "#{@name}: I AM SO FAST"

		Q(30).delay 1000