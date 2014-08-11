Q = require 'q'
_ = require 'lodash'

direction = require './direction'
{whilst} = require './util'

module.exports = class Player
	constructor: (@creature) ->

	tick: ->
		game = require './game'

		game.events.emit 'turn.player', 'player'

		whilst (-> game.renderer.hasMoreLogs()),
			->
				d = Q.defer()

				game.events.once 'key.enter', ->
					game.renderer.showMoreLogs()
					d.resolve()

				d.promise

		.then =>
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
		if @creature? then @creature.loadFromJSON json.creature
		else (require './creatures').fromJSON json.creature
		
		@

	toJSON: ->
		@