_ = require 'lodash'
winston = require 'winston'

game = require '../game'
direction = require '../direction'

exports.fromJSON = (json) ->
	e = switch json.type
		when 'creature' then new exports.Creature
		when 'item' then new exports.MapItem

	e.loadFromJSON json
	e

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
	
	loadFromJSON: (json) ->
		_.assign @, _.omit json, 'type'
		@

	toJSON: ->
		o = _.pick @, (v, k, o) ->
			(_.has o, k) and not (k in ['map'])

		o.type = @type
		o

exports.Creature = require './creature'
exports.MapItem = require './map-item'