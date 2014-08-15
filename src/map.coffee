_ = require 'lodash'

filter = (e, filter) ->
	switch
		when _.isFunction filter then filter e
		when _.isString filter then e.type is filter
		when _.isObject filter then _.where e, filter
		else yes

class exports.Map
	constructor: (@w, @h, @data = []) ->
		@entities = []

	entitiesAt: (x, y, f) ->
		_filter = (e) ->
			(filter e, f) and (e.x is x) and (e.y is y)

		e for e in @entities when _filter e

	listEntities: (f) ->
		e for e in @entities when filter e, f

	collidable: (x, y) ->
		return true unless 0 <= x < @w and 0 <= y < @h

		@data[y][x] is '#'

	seeThrough: (x, y) ->
		not @collidable x, y # temporary

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