Q = require 'q'
_ = require 'lodash'

direction = require './direction'

module.exports = class Player
	constructor: (@creature) ->

	tick: ->
		game = require './game'

		d = Q.defer()

		game.events.once 'key.*', (ch, key) =>
			moveOffset = direction.directions[key.name] ? [0, 0]

			if @creature.move moveOffset...
				d.resolve 12

			else
				switch key.full
					when 's' then game.save 'test-save.json'
					when 'S-s' then game.load 'test-save.json'

					when 'p'
						entities = @creature.map.entities
						entities.push entities.shift()
						@creature = entities[0]
						(require './game').camera.update()

					when 'd'
						winston = require 'winston'

						for e in @creature.map.entities
							winston.info e.toJSON()

				d.resolve 0

		d.promise

	loadFromJSON: (json) ->
		@creature = (require './entity-registry').fromJSON json.creature
		@

	toJSON: ->
		@