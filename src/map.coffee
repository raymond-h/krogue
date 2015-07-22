_ = require 'lodash'
TimeManager = require 'rl-time-manager'
Promise = require 'bluebird'

{repeat} = require './util'
log = require './log'

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
		@timeManager = new TimeManager(Promise.resolve.bind Promise)

	addEntity: (entities...) ->
		e.map = @ for e in entities
		@entities.push entities...
		@timeManager.add entities...
		@

	removeEntity: (e) ->
		e.map = null
		_.pull @entities, e
		@timeManager.remove e
		@

	entitiesAt: (x, y, f) ->
		_filter = (e) ->
			(filter e, f) and (e.x is x) and (e.y is y)

		e for e in @entities when _filter e

	listEntities: (f) ->
		e for e in @entities when filter e, f

	collidable: (x, y) ->
		if _.isObject x then {x, y} = x

		@data[y]?[x]?.collidable ? no

	hasBlockingEntities: (x, y) ->
		for e in @entities when e.x is x and e.y is y
			return yes if e.blocking

		no

	seeThrough: (x, y) ->
		if _.isObject x then {x, y} = x

		@data[y]?[x]?.seeThrough ? yes

	@compressData: (data) ->
		tileTable = []
		tileData = []

		findInTable = (tile) =>
			_.findIndex tileTable, ((t) -> _.isEqual t, tile), @

		currentTile = -1
		currentCount = 0

		for row, y in data
			for tile, x in row
				tti = findInTable tile

				if tti < 0
					tti = tileTable.length
					tileTable.push tile

				if tti isnt currentTile
					tileData.push [currentTile, currentCount] if currentTile >= 0

					currentTile = tti
					currentCount = 1

				else currentCount++

		tileData.push [currentTile, currentCount]

		{tileTable, tileData, rleWidth: data[0].length}

	@decompressData: ({tileTable, tileData, rleWidth}) ->
		if rleWidth?
			data = _.flatten(
				for [tti, count] in tileData
					repeat count, tileTable[tti]
			)

			tileData = for i in [0...data.length] by rleWidth
				data[i...i+rleWidth]

			tileData

		else
			for row, y in tileData
				for tti, x in row
					tileTable[tti]

	loadFromJSON: ({@id, @w, @h, data, @positions, entities}) ->
		if data.tileTable? and data.tileData?
			@data = Map.decompressData data

		else @data = data

		@addEntity entities...

	toJSON: ->
		{
			@id, @w, @h, @positions
			data: Map.compressData @data
			entities: @entities.filter (e) -> not e.isPlayer()
		}
