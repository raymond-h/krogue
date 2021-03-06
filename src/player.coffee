Promise = require 'bluebird'
_ = require 'lodash'

game = require './game'
random = require './random'
eventBus = require './event-bus'
message = require './message'
log = require './log'

{Stairs} = require './entities'
direction = require 'rl-directions'
vectorMath = require './vector-math'
{whilst} = require './util'
prompts = game.prompts

{p} = require './util'

module.exports = class Player
	constructor: (@creature) ->
		Object.defineProperty @, 'lookPos',
			enumerable: no
			get: => @_lookPos ? @creature
			set: (pos) => @_lookPos = pos

		@_lookPos = null

	tick: ->
		eventBus.emit 'turn.player.start'

		whilst (-> game.renderer.hasMoreLogs()),
			->
				prompts.actions null, ['more-logs']
				.then -> game.renderer.showMoreLogs()

		.then -> eventBus.waitOn 'action.**'

		.then ([action, params...]) => @doAction action, params...

		.then (cost) ->
			if not _.isNumber cost then cost = 0
			eventBus.emit 'turn.player.end'

	doAction: (action, params...) ->
		switch action
			when 'idle' then 12 # just wait a turn

			when 'direction'
				if (@creature.move params[0]) then 12 else 0

			when 'possess'
				nextEntity = (map) ->
					entities = map.entities
					entities.push entities.shift()

					if (entities[0].type is 'creature') then entities[0]
					else nextEntity map

				@creature = nextEntity @creature.map

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
					return message 'Never mind.' if not choice?

					{key, value} = choice
					message "You picked #{key}: #{value}!"

			when 'look'
				handler = (pos) =>
					@_lookPos = pos

				prompts.position null, default: @creature, progress: handler
				.then (pos) =>
					@_lookPos = null
					0

			when 'equip'
				prompts.list 'Equip which item?', @creature.inventory
				.then (choice) =>
					return message 'Never mind.' if not choice?

					{value: item} = choice

					if @creature.equip item
						6

					else message "
						If you do that, you're gonna overburden
						yourself. So don't do that.
					"

			when 'unequip'
				equips = for s,i of @creature.equipment
					item: i
					name: "#{i.name} (#{i.equipSlotUseString @creature})"

				prompts.list 'Put away which item?', equips
				.then (choice) =>
					return message 'Never mind.' if not choice?

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
					return message 'Never mind.' if not choice?
					{value: {item: reloadItem}} = choice

					invWithoutPicked = inventory.filter (v) -> v.item isnt reloadItem

					prompts.list 'Reload with which item?', invWithoutPicked
					.then (choice) =>
						return message 'Never mind.' if not choice?
						{value: {item: ammo}} = choice

						oldReloadItemName = reloadItem.name

						if reloadItem.reload ammo
							_.pull @creature.inventory, ammo
							message "
								Loaded #{oldReloadItemName} with #{ammo.name} - rock and roll!
							"

						else message "
							Dangit! Can't fit #{ammo.name} into #{oldReloadItemName}, it seems...
						"

			when 'pickup'
				items = @creature.map.entitiesAt @creature.x, @creature.y, 'item'

				switch items.length
					when 0
						message 'There, frankly, is nothing here!'

					when 1
						@creature.pickup items[0]
						3

					else
						prompts.multichoiceList 'Pick up which item?',
							("#{i.item.name}" for i in items)

						.then (choices) =>
							return message 'Never mind.' if not choices?

							for c in choices
								@creature.pickup items[c.index]

							3 * choices.length

			when 'drop'
				if @creature.inventory.length is 0
					message 'You empty your empty inventory onto the ground.'

				else
					prompts.multichoiceList 'Drop which item?', @creature.inventory
					.then (choices) =>
						return message 'Never mind.' if not choices?

						for c in choices
							@creature.drop c.value

						3 * choices.length

			when 'fire'
				prompts.position 'Fire where?', default: @creature
				.then (pos) =>
					offset = vectorMath.sub pos, @creature
					item = random.sample @creature.getItemsForSlot 'hand'

					if not item?
						message 'Your hand is surprisingly bad at firing bullets.'
						2
					else if not item.fire?
						message "
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
					return message 'Never mind.' if not choice?

					{value: item} = choice

					prompts.position 'Throw where?', default: @creature
					.then (pos) =>
						return message 'Never mind.' if not pos?

						offset = vectorMath.sub pos, @creature

						p @creature.throw item, offset
						.then -> 6

			when 'use-skill'
				skills = @creature.skills()

				if skills.length is 0
					message "
						You really don't have the skills to do that. Get better.
					"
					return

				prompts.list 'Use which skill?', skills
				.then (choice) =>
					return message 'Never mind.' if not choice?

					skill = choice.value

					p do =>
						return null if not skill.askParams?

						skill.askParams @creature

					.then (params) =>
						skill.use @creature, params

			when 'test-dir'
				prompts.direction 'Pick a direction!', cancelable: yes

				.then (dir) -> message "You answered: #{dir}"

			when 'test-yn'
				prompts.yesNo 'Are you sure?', cancelable: yes

				.then (reply) -> message "You answered: #{reply}"

			when 'test-multi'
				choices = [
					'apples'
					'bananas'
					'oranges'
				]

				prompts.multichoiceList 'Pick any fruits!', choices
				.then (choices) ->
					return message 'Cancelled.' if not choices?

					choices = choices.map (c) -> c.value

					if choices.length > 0
						message "You picked: #{choices.join ', '}"

					else message 'You picked none!!'

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

			when 'test-pos'
				prompts.position 'Test position!', default: @creature
				.then (pos) ->
					message "You picked position: #{pos.x},#{pos.y}" if pos?
					message "Never mind." if not pos?
