_ = require 'lodash'

{dasherize} = require './util'

exports.fromJSON = fromJSON = (json) ->
	Clazz = personalities[json.typeName]

	if Clazz? then (new Clazz).loadFromJSON json

	else null

Personality = class exports.Personality
	constructor: ->
		@weightMultiplier = 1

	withMultiplier: (@weightMultiplier) -> this

	weight: (creature) -> 0

	tick: (creature) -> 0

	loadFromJSON: (json) ->
		_.assign @, _.omit json, 'typeName'
		@

	toJSON: ->
		json = _.pick @, (v, k, o) -> _.has o, k
		json.typeName = @typeName
		json

exports.personalities = personalities =
	'flee-from-player': class exports.FleeFromPlayer extends Personality
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

	'random-walk': class exports.RandomWalk extends Personality
		weight: (creature) ->
			100

		tick: (creature) ->
			direction = require './direction'
			game = require './game'

			# game.message "Lorem ipsum dolor sit amet hurr durr gurr burr lol"

			# for i in [1..(game.random.int 1, 5)]
			# 	(game.message "Moo ##{game.random.int 0, 80}!")
			# if (game.random.int 0, 8) <= 2
			# 	game.message "That is of outmost curiosity!"

			creature.move (game.random.sample _.values direction.directions)...

			12

for typeName, Clazz of personalities
	Clazz::typeName ?= typeName