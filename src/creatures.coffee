Q = require 'q'

{Entity} = require './entities'

class exports.Creature extends Entity

class exports.Dummy extends exports.Creature
	tickRate: 10

	tick: ->
		Q 30

class exports.Player extends exports.Creature
	constructor: (g, m, x, y, @name, @speed = 12) ->
		super

		@symbol = '@'

	tickRate: -> @speed

	tick: ->
		d = Q.defer()

		@game.events.once 'key.*', (ch, key) =>
			moveOffset = switch key.name
				when 'up' then [0, -1]
				when 'down' then [0, 1]
				when 'left' then [-1, 0]
				when 'right' then [1, 0]
				else [0, 0]

			@move moveOffset...

			d.resolve @tickRate()

		d.promise