Q = require 'q'
_ = require 'lodash'

game = require './game'
log = require './log'

{Stairs} = require './entities'
direction = require './direction'
vectorMath = require './vector-math'
{whilst, arrayRemove} = require './util'
prompts = game.prompts

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
				Q @doAction action, params...

				.then (cost) -> if _.isNumber cost then cost else 0
				.nodeify d.makeNodeResolver()

			d.promise

	doAction: (action, params...) ->
		switch action
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
				nextEntity = (map) ->
					entities = map.entities
					entities.push entities.shift()

					if (entities[0].type is 'creature') then entities[0]
					else nextEntity map

				@creature = nextEntity @creature.map
				game.renderer.invalidate()

			when 'inventory'
				choices = [
					("#{i.name} (#{s})" for s,i of @creature.equipment)...
					(i.name for i in @creature.inventory)...
				]

				prompts.list 'Inventory', choices
				.then (choice) ->
					return game.message 'Never mind.' if not choice?

					{key, value} = choice
					game.message "You picked #{key}: #{value}!"

			when 'equip'
				prompts.list 'Equip which item?', @creature.inventory
				.then (choice) =>
					return game.message 'Never mind.' if not choice?

					{value: item} = choice
					prompts.list 'To what slot?', @creature.species.equipSlots
					.then (choice) =>
						return game.message 'Never mind.' if not choice?

						{value: slot} = choice
						@creature.equip slot, item
						6

			when 'unequip'
				equips = for s,i of @creature.equipment
					slot: s
					name: "#{i.name} (#{s})"

				prompts.list 'Put away which item?', equips
				.then (choice) =>
					return game.message 'Never mind.' if not choice?

					@creature.unequip choice.value.slot
					6

			when 'reload'
				equips = for s,i of @creature.equipment
					item: i
					name: "#{i.name} (#{s})"

				inventory = for i in @creature.inventory
					item: i
					name: i.name

				prompts.list 'Reload which item?', [equips..., inventory...].filter (v) -> v.item.reload?
				.then (choice) =>
					return game.message 'Never mind.' if not choice?
					{value: {item: reloadItem}} = choice

					invWithoutPicked = inventory.filter (v) -> v.item isnt reloadItem

					prompts.list 'Reload with which item?', invWithoutPicked
					.then (choice) =>
						return game.message 'Never mind.' if not choice?
						{value: {item: ammo}} = choice

						arrayRemove @creature.inventory, ammo
						reloadItem.reload ammo
						game.message "Loaded #{reloadItem.name} with #{ammo.name} - rock and roll!"

			when 'pickup'
				items = @creature.map.entitiesAt @creature.x, @creature.y, 'item'

				switch items.length
					when 0
						game.message 'There, frankly, is nothing here!'

					when 1
						@creature.pickup items[0]
						3

					else
						prompts.multichoiceList 'Pick up which item?',
							("#{i.item.name}" for i in items)
						
						.then (choices) =>
							return game.message 'Never mind.' if not choices?
							
							for c in choices
								@creature.pickup items[c.index]

							3 * choices.length

			when 'drop'
				if @creature.inventory.length is 0
					game.message 'You empty your empty inventory onto the ground.'

				else
					prompts.multichoiceList 'Drop which item?', @creature.inventory
					.then (choices) =>
						return game.message 'Never mind.' if not choices?

						for c in choices
							@creature.drop c.value

						3 * choices.length

			when 'fire'
				prompts.position 'Fire where?', default: @creature
				.then (pos) =>
					offset = vectorMath.sub pos, @creature
					item = @creature.equipment['right hand']

					if not item?
						game.message 'Your hand is surprisingly bad at firing bullets.'
						2
					else if not item.fire?
						game.message "
							You find the lack of bullets
							from your #{item.name} disturbing.
						"
						2
					else
						Q item.fire @creature, offset
						.thenResolve 6

			when 'attack'
				prompts.direction 'Attack in what direction?'

				.then (dir) =>
					@creature.attack dir

					12

			when 'throw'
				prompts.list 'Throw which item?', @creature.inventory
				.then (choice) =>
					return game.message 'Never mind.' if not choice?

					{value: item} = choice

					prompts.position 'Throw where?', default: @creature
					.then (pos) =>
						return game.message 'Never mind.' if not pos?

						offset = vectorMath.sub pos, @creature

						Q @creature.throw item, offset
						.thenResolve 6

			when 'test-dir'
				prompts.direction 'Pick a direction!', cancelable: yes

				.then (dir) -> game.message "You answered: #{dir}"

			when 'test-yn'
				prompts.yesNo 'Are you sure?', cancelable: yes

				.then (reply) -> game.message "You answered: #{reply}"

			when 'test-multi'
				choices = [
					'apples'
					'bananas'
					'oranges'
				]

				prompts.multichoiceList 'Pick any fruits!', choices
				.then (choices) ->
					return game.message 'Cancelled.' if not choices?

					choices = choices.map (c) -> c.value

					if choices.length > 0
						game.message "You picked: #{choices.join ', '}"

					else game.message 'You picked none!!'

			when 'down-stairs'
				[stairs] = @creature.map.entitiesAt @creature.x, @creature.y,
					(e) -> e.type is 'stairs' and e.down

				if stairs?
					{target: {map, position}} = stairs
					game.goTo map, position

			when 'up-stairs'
				[stairs] = @creature.map.entitiesAt @creature.x, @creature.y,
					(e) -> e.type is 'stairs' and not e.down

				if stairs?
					{target: {map, position}} = stairs
					game.goTo map, position

			when 'line-effect'
				target = @creature.findNearest null, (-> yes)

				game.renderer.effectLine @creature, target, time: 500, symbol: '*'

			when 'test-pos'
				prompts.position 'Test position!', default: @creature
				.then (pos) ->
					game.message "You picked position: #{pos.x},#{pos.y}" if pos?
					game.message "Never mind." if not pos?