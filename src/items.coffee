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
				emit = (a...) -> game.events.emit a...

				emit 'game.creature.handgun.fire', creature, @, dir

				endPos =
					direction.parse dir
					.map (axis) => axis * (@range ? 1)
					.map (axis, i) =>
						(if i is 0 then creature.x else creature.y) + axis

				found = creature.raytraceUntilBlocked {x: endPos[0], y: endPos[1]}

				switch found.type
					when 'none'
						emit 'game.creature.handgun.hit.none', creature, @, dir

					when 'wall'
						emit 'game.creature.handgun.hit.wall',
							creature, @, dir, {x: endPos[0], y: endPos[1]}

					when 'creature'
						target = found.creature

						emit 'game.creature.handgun.hit.creature', creature, @, dir, target
						target.damage 10, creature
]

exports.items = items = {}
for Clazz in itemsArray
	exports.items[Clazz::typeName] = Clazz