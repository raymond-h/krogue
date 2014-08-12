_ = require 'lodash'

class exports.Map
	constructor: (@w, @h, @data = []) ->
		@entities = []

	entitiesAt: (x, y, type) ->
		filter = (e) ->
			matchesType =
				if type? then (e.type is type)
				else yes

			matchesType and (e.x is x) and (e.y is y)

		e for e in @entities when filter e

	collidable: (x, y) ->
		return true unless 0 <= x < @w and 0 <= y < @h

		@data[y][x] is '#'

	@fromJSON = (json) ->
		map = new exports.Map json.w, json.h, json.data

		map.entities =
			for e in json.entities
				ent = (require './entities').fromJSON e
				ent.map = map
				ent

		map

	toJSON: ->
		{
			@w, @h, @data
			entities: @entities.filter (e) ->
				e isnt (require './game').player.creature
		}