Q = require 'q'
_ = require 'lodash'
winston = require 'winston'

game = require './game'

direction = require './direction'
{whilst, arrayRemove} = require './util'
prompts = require './prompts'

module.exports = class Player
	constructor: (@creature) ->

	tick: ->
		game.emit 'turn.player', 'player'

		whilst (-> game.renderer.hasMoreLogs()),
			->
				prompts.actions null, ['more-logs']
				.then -> game.renderer.showMoreLogs()

		.then =>
			d = Q.defer()

			game.once 'action.**', (action, params...) =>
				Q switch action
					when 'idle' then 12 # just wait a turn

					when 'direction'
						if (@creature.move params[0]) then 12 else 0

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
						choices = [
							("#{i.name} (#{s})" for s,i of @creature.equipment)...
							(i.name for i in @creature.inventory)...
						]

						prompts.list 'Inventory', choices

						.then ({cancelled, key, value}) ->
							if cancelled
								game.message 'Never mind.'

							else
								game.message "You picked #{key}: #{value}!"

					when 'equip'
						prompts.list 'Equip which item?', @creature.inventory
						.then ({cancelled, value: item}) =>
							return game.message 'Never mind.' if cancelled

							prompts.list 'To what slot?', @creature.species.equipSlots
							.then ({cancelled, value: slot}) =>
								return game.message 'Never mind.' if cancelled

								@creature.equip slot, item
								6

					when 'unequip'
						equips = for s,i of @creature.equipment
							slot: s
							name: "#{i.name} (#{s})"

						prompts.list 'Put away which item?', equips
						.then ({cancelled, value}) =>
							return game.message 'Never mind.' if cancelled

							@creature.unequip value.slot
							6

					when 'pickup'
						items = @creature.map.entitiesAt @creature.x, @creature.y, 'item'

						switch items.length
							when 0
								game.message 'There, frankly, is nothing here!'

							when 1
								@creature.pickup items[0]
								3

							else
								prompts.list 'Pick up which item?', ("#{i.item.name}" for i in items)
								.then ({cancelled, index}) =>
									return game.message 'Never mind.' if cancelled
									
									@creature.pickup items[index]
									3

					when 'drop'
						if @creature.inventory.length is 0
							game.message 'You empty your empty inventory onto the ground.'

						else
							prompts.list 'Drop which item?', @creature.inventory
							.then ({cancelled, value: item}) =>
								return game.message 'Never mind.' if cancelled

								@creature.drop item
								3

					when 'fire'
						prompts.direction 'Fire in what direction?'

						.then (dir) =>
							item = @creature.equipment['right hand']

							if not item?
								game.message 'Your hand is surprisingly bad at firing bullets.'
								2
							else if not item.fire?
								game.message "You find the lack of bullets from your #{item.name} disturbing."
								2
							else
								item.fire @creature, dir
								6

					when 'kick'
						prompts.direction 'Kick in what direction?'

						.then (dir) =>
							@creature.kick dir

							12

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