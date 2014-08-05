Q = require 'q'

{Entity} = require './entities'

class exports.Creature extends Entity

_ = require 'lodash'

directions =
	up: [0, -1]
	down: [0, 1]
	left: [-1, 0]
	right: [1, 0]

class exports.Dummy extends exports.Creature
	symbol: 'D'

	tickRate: 3

	tick: ->
		@move (_.sample _.values directions)...

		Q 12

class exports.Player extends exports.Creature
	constructor: (g, m, x, y, @name, @speed = 12) ->
		super

		@symbol = '@'

	tickRate: -> @speed

	tick: ->
		d = Q.defer()

		@game.events.once 'key.*', (ch, key) =>
			moveOffset = directions[key.name] ? [0, 0]

			if @move moveOffset...
				d.resolve @tickRate()

			else d.resolve 0

		d.promise