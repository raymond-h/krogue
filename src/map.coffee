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

	addEntity: (e, addToTimeManager) ->
		e.map = @
		@entities.push e
		if (addToTimeManager ? yes)
			(require './game').timeManager.targets.push e
		@

	addEntities: (entities...) ->
		entities = _.flatten entities

		@addEntity e for e in entities

	removeEntity: (e) ->
		e.map = null
		arrayRemove @entities, e
		(require './game').timeManager.targets.remove e
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

		@data[y][x] is '#'

	seeThrough: (x, y) ->
		if _.isObject x then {x, y} = x
		
		not @collidable x, y # temporary

	@fromJSON = (json) ->
		map = new exports.Map json.w, json.h, json.data

		for e in json.entities
			map.addEntity (require './entities').fromJSON e

		map

	toJSON: ->
		{
			@w, @h, @data
			entities: @entities.filter (e) -> not e.isPlayer()
		}