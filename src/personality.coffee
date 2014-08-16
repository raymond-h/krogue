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
			if (
				(creature.canSee game.player.creature) and 
				(creature.distanceSqTo game.player.creature) < (@safeDist*@safeDist)
			)
				100

			else 0

		tick: (creature) ->
			direction = (require './direction')
			game = (require './game')

			dir = direction.opposite(creature.directionTo game.player.creature)

			creature.move (direction.parse dir)...

			12

	class exports.RandomWalk extends Personality
		typeName: 'random-walk'

		weight: (creature) ->
			100

		tick: (creature) ->
			direction = require './direction'
			game = require './game'

			creature.move (direction.parse game.random.direction 8)...

			12

	class exports.WantItems extends Personality
		typeName: 'want-items'

		constructor: (@range = 1, @wantedItems = null) ->

		weight: (creature) ->
			{distanceSq} = require './util'

			nearest = creature.findNearest @range, (e) ->
				e.type is 'item' and creature.canSee e

			if nearest? then 100 else 0

		tick: (creature) ->
			direction = require './direction'
			{distanceSq} = require './util'

			itemsHere = creature.map.entitiesAt creature.x, creature.y, 'item'

			if itemsHere.length > 0
				item = itemsHere[0]
				creature.pickup item

			else
				nearest = creature.findNearest @range, (e) ->
					e.type is 'item' and creature.canSee e

				dir = creature.directionTo nearest
				creature.move (direction.parse dir)...
				12
]

exports.personalities = personalities = {}
for Clazz in personalitiesArray
	exports.personalities[Clazz::typeName] = Clazz