_ = require 'lodash'

exports.fromJSON = (json) ->
	if personalities[json.typeName]?
		_.assign (new personalities[json.typeName]),
			_.omit json, 'typeName'

	else null

Personality = class exports.Personality
	constructor: ->
		@weightMultiplier = 1

	withMultiplier: (@weightMultiplier) -> this

	weight: (creature) -> 0

	tick: (creature) -> 0

	toJSON: ->
		json = _.pick @, (v, k, o) -> _.has o, k
		json.typeName = @typeName
		json

personalitiesArray = [
	class exports.FleeFromPlayer extends Personality
		typeName: 'flee-from-player'

		constructor: (@safeDist) ->
			super

		weight: (creature) ->
			{distanceSq} = require './util'
			game = require './game'
			if (distanceSq game.player.creature, creature) < (@safeDist*@safeDist)
				100

			else 0

		tick: (creature) ->
			direction = (require './direction')
			game = (require './game')

			dir = direction.getDirection game.player.creature, creature

			creature.move (direction.parse dir)...

			12

	class exports.RandomWalk extends Personality
		typeName: 'random-walk'

		weight: (creature) ->
			100

		tick: (creature) ->
			direction = require './direction'
			game = require './game'

			creature.move (game.random.sample _.values direction.directions)...

			12

	class exports.WantItems extends Personality
		typeName: 'want-items'

		constructor: (@range = 1, @wantedItems = null) ->

		weight: (creature) ->
			{distanceSq} = require './util'

			nearbyItems = creature.map.listEntities (e) =>
				e.type is 'item' and (distanceSq creature, e) < @range*@range

			if nearbyItems.length > 0 then 100 else 0

		tick: (creature) ->
			{distanceSq} = require './util'

			itemsHere = creature.map.entitiesAt creature.x, creature.y, 'item'

			if itemsHere.length > 0
				item = itemsHere[0]
				creature.pickup item

			else
				items = creature.map.listEntities 'item'

				nearest = [Infinity, null]
				for item in items
					dSq = (distanceSq creature, item)
					if dSq < nearest[0]*nearest[0]
						nearest = [dSq, item]

				direction = (require './direction')
				
				dir = direction.getDirection creature, nearest[1]
				creature.move (direction.parse dir)...
				12
]

exports.personalities = personalities = {}
for Clazz in personalitiesArray
	exports.personalities[Clazz::typeName] = Clazz