Q = require 'q'
_ = require 'lodash'
winston = require 'winston'

direction = require './direction'
{whilst, arrayRemove} = require './util'
prompts = require './prompts'

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

				Q switch key.full
					when 's' then game.save 'test-save.json'
					when 'S-s'
						prompts.yesNo 'Are you sure you want to load?'

						.then (doLoad) ->
							if doLoad
								game.load 'test-save.json'
								game.message "Loaded."

					when 't'
						prompts.yesNo 'Are you sure?'

						.then (reply) ->
							game.message "You replied: #{reply}"

					when 'p'
						entities = @creature.map.entities
						entities.push entities.shift()
						@creature = entities[0]
						game.camera.update()

					when 'd'
						winston = require 'winston'

						for e in @creature.map.entities
							winston.info e.toJSON()

					when 'i'
						for item in @creature.inventory
							game.message "#{item.symbol} - #{item.name};"

					when ','
						map = @creature.map
						items = map.entitiesAt @creature.x, @creature.y, 'item'
						if items.length > 0
							@creature.pickup items[0]
							3

						else game.message 'There, frankly, is nothing here!'

					when 'S-d'
						item = @creature.inventory[0]
						@creature.drop item

				.then (cost = 0) -> d.resolve cost

			d.promise

	loadFromJSON: (json) ->
		if @creature? then @creature.loadFromJSON json.creature
		else (require './entities').fromJSON json.creature
		
		@

	toJSON: ->
		@