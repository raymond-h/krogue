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

			game.events.once 'action.**', (action, params...) =>
				Q switch action
					when 'idle' then 12 # just wait a turn

					when 'direction'
						moveOffset = direction.parse params[0]

						if (@creature.move moveOffset...) then 12 else 0

					when 'save'
						game.save 'test-save.json'

					when 'load'
						prompts.yesNo 'Are you sure you want to load?'

						.then (doLoad) ->
							if doLoad
								game.load 'test-save.json'
								game.message "Loaded."

					when 'possess'
						entities = @creature.map.entities
						entities.push entities.shift()
						@creature = entities[0]
						game.camera.update()

					when 'inventory'
						# winston.info 'Accessing inventory!!'
						for item in @creature.inventory
							# winston.info 'Wow!!!'
							game.message "#{item.symbol} - #{item.name};"
							# winston.info 'Amazing!!!'
							null
						# winston.info 'Done with inventory!'

					when 'pickup'
						map = @creature.map
						items = map.entitiesAt @creature.x, @creature.y, 'item'
						if items.length > 0
							@creature.pickup items[0]
							3

						else game.message 'There, frankly, is nothing here!'

					when 'drop'
						item = @creature.inventory[0]
						@creature.drop item

					when 'test-dir'
						prompts.direction 'Pick a direction!'

						.then (dir) -> game.message "You answered: #{dir}"

					when 'test-yn'
						prompts.yesNo 'Are you sure?'

						.then (reply) -> game.message "You answered: #{reply}"

				.then (cost) -> if _.isNumber cost then cost else 0

				.nodeify d.makeNodeResolver()

			d.promise

	loadFromJSON: (json) ->
		if @creature? then @creature.loadFromJSON json.creature
		else (require './entities').fromJSON json.creature
		
		@

	toJSON: ->
		@