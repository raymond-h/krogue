Promise = require 'bluebird'
_ = require 'lodash'

game = require './game'
log = require './log'

{Stairs} = require './entities'
direction = require './direction'
vectorMath = require './vector-math'
{whilst, arrayRemove} = require './util'
prompts = game.prompts

{p} = require './util'

module.exports = class Player
	constructor: (@creature) ->

	tick: ->
		game.emit 'turn.player', 'player'

		whilst (-> game.renderer.hasMoreLogs()),
			->
				prompts.actions null, ['more-logs']
				.then -> game.renderer.showMoreLogs()

		.then -> game.waitOnEvent 'action.**'

		.then ([action, params...]) => @doAction action, params...

		.then (cost) -> if _.isNumber cost then cost else 0

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
						p game.load 'test-save.json'
						.then -> game.message "Loaded."

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
					(
						for i in @creature.equipment
							"#{i.name} (#{i.equipSlotUseString @creature})"
					)...
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
					# prompts.list 'To what slot?', @creature.species.equipSlots
					# .then (choice) =>
					# 	return game.message 'Never mind.' if not choice?

					# 	{value: slot} = choice
					if @creature.equip item
						6

					else game.message "
						If you do that, you're gonna overburden
						yourself. So don't do that.
					"

			when 'unequip'
				equips = for s,i of @creature.equipment
					item: i
					name: "#{i.name} (#{i.equipSlotUseString @creature})"

				prompts.list 'Put away which item?', equips
				.then (choice) =>
					return game.message 'Never mind.' if not choice?

					@creature.unequip choice.value.item
					6

			when 'reload'
				equips = for s,i of @creature.equipment
					item: i
					name: "#{i.name} (#{i.equipSlotUseString @creature})"

				inventory = for i in @creature.inventory
					item: i
					name: i.name

				reloadableItems = [equips..., inventory...].filter (v) -> v.item.reload?

				prompts.list 'Reload which item?', reloadableItems
				.then (choice) =>
					return game.message 'Never mind.' if not choice?
					{value: {item: reloadItem}} = choice

					invWithoutPicked = inventory.filter (v) -> v.item isnt reloadItem

					prompts.list 'Reload with which item?', invWithoutPicked
					.then (choice) =>
						return game.message 'Never mind.' if not choice?
						{value: {item: ammo}} = choice

						oldReloadItemName = reloadItem.name

						if reloadItem.reload ammo
							arrayRemove @creature.inventory, ammo
							game.message "
								Loaded #{oldReloadItemName} with #{ammo.name} - rock and roll!
							"

						else game.message "
							Dangit! Can't fit #{ammo.name} into #{oldReloadItemName}, it seems...
						"

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
					item = game.random.sample @creature.getItemsForSlot 'hand'

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
						p item.fire @creature, offset
						.then -> 6

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

						p @creature.throw item, offset
						.then -> 6

			when 'use-skill'
				skills = @creature.skills()

				if skills.length is 0
					game.message "
						You really don't have the skills to do that. Get better.
					"
					return

				prompts.list 'Use which skill?', skills
				.then (choice) =>
					return game.message 'Never mind.' if not choice?

					skill = choice.value

					p do =>
						return null if not skill.askParams?

						skill.askParams @creature

					.then (params) =>
						skill.use @creature, params

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