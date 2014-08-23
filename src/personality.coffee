_ = require 'lodash'

game = require './game'

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
			if (
				(creature.canSee game.player.creature) and
				(creature.distanceSqTo game.player.creature) < (@safeDist*@safeDist)
			)
				100

			else 0

		tick: (creature) ->
			direction = (require './direction')

			creature.moveAwayFrom game.player.creature

			12

	class exports.RandomWalk extends Personality
		typeName: 'random-walk'

		weight: (creature) ->
			100

		tick: (creature) ->
			direction = require './direction'

			creature.move game.random.direction 8

			12

	class exports.WantItems extends Personality
		typeName: 'want-items'

		constructor: (@range = 1, @wantedItems = null) ->

		weight: (creature) ->
			nearest = creature.findNearest @range, (e) ->
				e.type is 'item' and creature.canSee e

			if nearest? then 100 else 0

		tick: (creature) ->
			nearest = creature.findNearest @range, (e) ->
				e.type is 'item' and creature.canSee e

			creature.moveTo nearest

			itemsHere = creature.map.entitiesAt creature.x, creature.y, 'item'

			if itemsHere.length > 0
				item = itemsHere[0]
				creature.pickup item

			12

	class exports.AttackAllButSpecies extends Personality
		typeName: 'attack-all-but-species'

		constructor: (@species) ->

		locateTarget: (creature) ->
			creature.findNearest null, (e) =>
				e isnt creature and
				(e.type is 'creature') and
				(e.species.typeName isnt @species) and
				(creature.canSee e)

		weight: (creature) ->
			if (@locateTarget creature)? then 100 else 0

		tick: (creature) ->
			target = @locateTarget creature

			winston = require 'winston'
			winston.info "Metroid #{creature.x},#{creature.y} attacking #{target}"
			winston.info "-- #{target.species.name} #{target.x},#{target.y}"

			creature.moveTo target

			if Math.abs(creature.x - target.x) <= 1 and
					Math.abs(creature.y - target.y) <= 1

				creature.kick creature.directionTo target

			12
]

exports.personalities = personalities = {}
for Clazz in personalitiesArray
	exports.personalities[Clazz::typeName] = Clazz