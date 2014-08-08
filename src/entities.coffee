_ = require 'lodash'
winston = require 'winston'

class exports.Entity
	symbol: '-'

	constructor: (@game, @map, @x, @y) ->

	setPos: (x, y) ->
		@x = x
		@y = y
		@game.renderer.invalidate()

	move: (x, y) ->
		canMoveThere = not @collidable @x+x, @y+y
		
		@setPos @x+x, @y+y if canMoveThere

		canMoveThere

	collidable: (x, y) ->
		(@map.collidable x, y) or (@map.objectPresent x, y)?

	tickRate: 0

	tick: ->

	@fromJSON: (game, json) ->
		Clazz = (require './entity-registry').type[json.type]

		if Clazz?
			e = new Clazz game
			e.loadFromJSON json
			e

		else null

	loadFromJSON: (json) ->
		_.assign @, _.omit json, 'type'
		@

	toJSON: ->
		o = _.pick @, (v, k, o) ->
			(_.has o, k) and not (k in ['game', 'map', 'symbol'])

		o.type = @type
		o