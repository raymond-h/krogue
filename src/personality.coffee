_ = require 'lodash'

exports.personalities = personalities = {}

exports.add = add = (clazz) ->
	dasherize = (className) ->
		className
		.replace /(\w)(?=[A-Z])/g, '$1-'
		.toLowerCase()

	clazz::typeName ?= dasherize clazz.name

	name = (_.result clazz::, 'typeName')

	personalities[name] = clazz

exports.fromJSON = fromJSON = (json) ->
	Clazz = personalities[json.type]

	if Clazz?
		(new Clazz).loadFromJSON json

	else null

class exports.BasePersonality
	weight: (creature) -> 0

	tick: (creature) -> 0

	loadFromJSON: (json) ->
		_.assign @, _.omit json, 'type'
		@

	toJSON: ->
		o = _.pick @, (v, k, o) -> _.has o, k
		o.type = @typeName
		o

add class exports.FleeFromPlayer extends exports.BasePersonality
	constructor: (@safeDist) ->

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

add class exports.RandomWalk extends exports.BasePersonality
	weight: (creature) ->
		50

	tick: (creature) ->
		direction = require './direction'
		game = require './game'

		# game.message "Lorem ipsum dolor sit amet hurr durr gurr burr lol"

		# game.message "Moo! #{game.random.int 0, 80}"
		# if (game.random.int 0, 8) <= 2
		# 	game.message "That is of outmost curiosity!"

		creature.move (game.random.sample _.values direction.directions)...

		12