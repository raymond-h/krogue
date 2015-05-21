_ = require 'lodash'

FeatureGen = require './features'

class exports.GenerationManager
	constructor: (@connections = {}) ->

	addConnection: (map0, p0, map1, p1) ->
		positions = @connections[map0] ?= {}
		positions[p0] = [map1, p1]

		positions = @connections[map1] ?= {}
		positions[p1] = [map0, p0]

	getConnections: (map, position) ->
		if position? then @connections[map][position]
		else @connections[map]

	generateMap: (id) ->
		[path, level] = id.split '-'
		level = Number level

		@generateConnections id, path, level

		map = @handleMap id, path, level

		map.id = id

		map

	generateConnections: (thisMap, path, level) ->
		exits = if path is 'main'
			exit: ["main-#{level+1}", 'entrance']

		for name, [map, target] of exits
			@addConnection thisMap, name, map, target

	handleMap: (id, path, level) ->
		connections = @getConnections id

		map =
			if level is 1
				@generateStart path, 1, connections

			else if level > 1
				@generateCave path, (level - 1), connections

		FeatureGen.generateFeatures path, level, map

		map

	generateStart: (path, level, connections) ->
		(require './generator-start').generateMap path, level, connections

	generateCave: (path, level, connections) ->
		(require './generator-cave').generateMap path, level, connections