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
				vectorMath = require './vector-math'

				emit = (a...) -> game.events.emit a...

				emit 'game.creature.fire', creature, @, dir

				offset = direction.parse dir
				endPos =
					vectorMath.add creature, (
						vectorMath.mult offset, @range
					)

				found = creature.raytraceUntilBlocked endPos

				switch found.type
					when 'none'
						emit 'game.creature.fire.hit.none', creature, @, dir

					when 'wall'
						emit 'game.creature.fire.hit.wall',
							creature, @, dir, found

					when 'creature'
						target = found.creature

						emit 'game.creature.fire.hit.creature', creature, @, dir, target
						target.damage 10, creature
]

exports.items = items = {}
for Clazz in itemsArray
	exports.items[Clazz::typeName] = Clazz