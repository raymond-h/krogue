_ = require 'lodash'

class exports.Map
	constructor: (@game, @w, @h, @data = []) ->
		@entities = []

	objectPresent: (x, y) ->
		for e in @entities
			return e if (e.x is x and e.y is y)

		null

	collidable: (x, y) ->
		return true unless 0 <= x < @w and 0 <= y < @h

		@data[y][x] is '#'

	@fromJSON = (game, json) ->
		map = new exports.Map game, json.w, json.h, json.data

		map.entities =
			for e in json.entities
				ent = (require './entity-registry').fromJSON game, e
				ent.map = map
				ent

		map

	toJSON: ->
		{
			@w, @h, @data
			entities: e for e in @entities when e isnt @game.player
		}