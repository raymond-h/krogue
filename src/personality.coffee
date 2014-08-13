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
			distanceSq = (e0, e1) ->
				[dx, dy] = [e1.x-e0.x, e1.y-e0.y]
				dx*dx + dy*dy

			game = require './game'
			if (distanceSq game.player.creature, creature) < (@safeDist*@safeDist)
				100

			else 0

		tick: (creature) ->
			direction = (require './direction')
			ac = (require './game').player.creature

			dir = direction.getDirection ac.x, ac.y, creature.x, creature.y

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
]

exports.personalities = personalities = {}
for Clazz in personalitiesArray
	exports.personalities[Clazz::typeName] = Clazz