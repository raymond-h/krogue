_ = require 'lodash'
{arrayRemove} = require './util'

filter = (e, filter) ->
	switch
		when _.isFunction filter then filter e
		when _.isString filter then e.type is filter
		when _.isObject filter then _.where e, filter
		else yes

class exports.Map
	constructor: (@w, @h, @data = []) ->
		@entities = []
		@positions = {}

	addEntity: (entities...) ->
		e.map = @ for e in entities
		@entities.push entities...
		@

	removeEntity: (e) ->
		e.map = null
		arrayRemove @entities, e
		@

	entitiesAt: (x, y, f) ->
		_filter = (e) ->
			(filter e, f) and (e.x is x) and (e.y is y)

		e for e in @entities when _filter e

	listEntities: (f) ->
		e for e in @entities when filter e, f

	collidable: (x, y) ->
		if _.isObject x then {x, y} = x

		return true unless 0 <= x < @w and 0 <= y < @h

		@data[y][x].collidable

	hasBlockingEntities: (x, y) ->
		for e in @entities when e.x is x and e.y is y
			return yes if e.blocking

		no

	seeThrough: (x, y) ->
		if _.isObject x then {x, y} = x
		
		not @collidable x, y # temporary

	loadFromJSON: ({@id, @w, @h, @data, @positions, entities}) ->
		@addEntity entities...

	toJSON: ->
		{
			@id, @w, @h, @data, @positions
			entities: @entities.filter (e) -> not e.isPlayer()
		}