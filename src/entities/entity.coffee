_ = require 'lodash'

log = require '../log'
game = require '../game'
direction = require '../direction'

class exports.Entity
	symbol: '-'
	blocking: no

	constructor: (@map, @x, @y) ->

	setPos: (x, y) ->
		if _.isObject x then {x, y} = x

		@x = x
		@y = y
		game.renderer.invalidate()

	movePos: (x, y) ->
		if _.isString x then x = direction.parse x
		if _.isObject x then {x, y} = x

		@setPos @x+x, @y+y

	isPlayer: -> no

	tickRate: 0

	tick: ->

	toJSON: ->
		_.pick @, (v, k, o) ->
			(_.has o, k) and not (k in ['map'])

exports.Creature = require './creature'
exports.MapItem = require './map-item'

class exports.Stairs extends exports.Entity
	symbol: -> if @down then 'stairsDown' else 'stairsUp'
	type: 'stairs'
	blocking: no

	constructor: (m, x, y, @target = {}) ->
		super
		@down = no