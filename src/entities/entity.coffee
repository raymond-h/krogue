_ = require 'lodash'

log = require '../log'
direction = require 'rl-directions'

{distanceSq} = require '../util'

class exports.Entity
	blocking: no

	constructor: ({@map, @x, @y}) ->

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

class exports.MapItem extends exports.Entity
	type: 'item'
	blocking: no

	constructor: ({@item}) ->
		super

class exports.Stairs extends exports.Entity
	type: 'stairs'
	blocking: no

	constructor: ({@target}) ->
		super
		@target ?= {}
		@down = no
