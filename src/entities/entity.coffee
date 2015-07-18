_ = require 'lodash'

log = require '../log'
game = require '../game'
direction = require '../direction'

{distanceSq} = require '../util'

class exports.Entity
	symbol: '-'
	blocking: no

	constructor: (@map, @x, @y) ->

	setPos: (x, y) ->
		if _.isObject x then {x, y} = x

		@x = x
		@y = y

	movePos: (x, y) ->
		if _.isString x then x = direction.parse x
		if _.isObject x then {x, y} = x

		@setPos @x+x, @y+y

	distanceSqTo: (to) ->
		distanceSq @, to

	distanceTo: (to) ->
		Math.sqrt @distanceSqTo to

	inRange: (range, to) ->
		(@distanceSqTo to) <= (range*range)

	directionTo: (to) ->
		direction.getDirection @, to

	isPlayer: -> no

	tickRate: 0

	tick: ->

	toJSON: ->
		_.pick @, (v, k, o) ->
			(_.has o, k) and not (k in ['map'])

class exports.MapItem extends exports.Entity
	symbol: -> @item.symbol
	type: 'item'
	blocking: no

	constructor: (m, x, y, @item) ->
		super

class exports.Stairs extends exports.Entity
	symbol: -> if @down then 'stairsDown' else 'stairsUp'
	type: 'stairs'
	blocking: no

	constructor: (m, x, y, @target = {}) ->
		super
		@down = no