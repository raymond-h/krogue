Q = require 'q'
_ = require 'lodash'

{Entity} = require './entities'

directions =
	up: [0, -1]
	down: [0, 1]
	left: [-1, 0]
	right: [1, 0]

class exports.Creature extends Entity

class exports.Dummy extends exports.Creature
	type: 'dummy'
	symbol: 'D'

	tickRate: 3

	tick: ->
		game = require './game'

		@move (game.random.sample _.values directions)...

		12

class exports.FastDummy extends exports.Dummy
	type: 'fast-dummy'
	tickRate: 30

	symbol: 'F'

class exports.PlayerC extends exports.Creature
	type: 'player'
	symbol: '@'

	constructor: (m, x, y, @name, @speed = 12) ->
		super

	setPos: ->
		super
		(require './game').camera.update()

	tickRate: -> @speed

	tick: ->
		(require './game').player.tick()