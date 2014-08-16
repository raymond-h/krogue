_ = require 'lodash'
winston = require 'winston'

exports.fromJSON = (json) ->
	e = switch json.type
		when 'creature' then new exports.Creature
		when 'item' then new exports.MapItem

	e.loadFromJSON json
	e

class exports.Entity
	symbol: '-'

	constructor: (@map, @x, @y) ->

	setPos: (x, y) ->
		@x = x
		@y = y
		(require '../game').renderer.invalidate()

	movePos: (x, y) ->
		@setPos @x+x, @y+y

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