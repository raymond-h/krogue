_ = require 'lodash'

exports.fromJSON = (json) ->
	if items[json.typeName]?
		_.assign (new items[json.typeName]),
			_.omit json, 'typeName'

	else null

Item = class exports.Item
	symbol: 'I'

	toJSON: ->
		json = _.pick @, (v, k, o) -> _.has o, k
		json.typeName = @typeName
		json

itemsArray = [
	class exports.PeculiarObject extends Item
		typeName: 'peculiar-object'

		name: 'peculiar object'
		symbol: 'O'

	class exports.Gun extends Item
		typeName: 'gun'

		name: 'gun'
		symbol: '/'

		fire: (a...) ->
			fn = @fireHandlers[@gunType ? '_dud']

			fn.apply @, a

		fireHandlers:
			'_dud': (creature, dir) ->
				(require './game').message 'Nothing happens; this gun is a dud.'

			'handgun': (creature, dir) ->
				game = require './game'
				direction = require './direction'

				game.message 'BANG!'

				endPos =
					direction.parse dir
					.map (axis) => axis * (@range ? 1)
					.map (axis, i) =>
						(if i is 0 then creature.x else creature.y) + axis

				found = creature.raytraceUntilBlocked {x: endPos[0], y: endPos[1]}

				switch found.type
					when 'none' then game.message 'You hit nothing...'
					when 'wall' then game.message 'The bullet strikes a wall...'
					when 'creature'
						target = found.creature

						game.message "The bullet hits the #{target.species.name}!"
						target.damage 10, creature

					else game.message 'The bullet seems to have disappeared...'
]

exports.items = items = {}
for Clazz in itemsArray
	exports.items[Clazz::typeName] = Clazz