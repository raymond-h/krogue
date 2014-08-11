Q = require 'q'
_ = require 'lodash'

direction = require './direction'
{whilst} = require './util'

keys = {
	'1': 'down-left'
	'2': 'down'
	'3': 'down-right'
	'4': 'left'
	'5': 'idle'
	'6': 'right'
	'7': 'up-left'
	'8': 'up'
	'9': 'up-right'

	'up', 'down', 'left', 'right'
	'.': 'idle'
}

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
				moveDir = keys[key.full]
				if moveDir?
					return d.resolve 12 if moveDir is 'idle'

					moveOffset = direction.parse moveDir

					return d.resolve (
						if (@creature.move moveOffset...) then 12 else 0
					)

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