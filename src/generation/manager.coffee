_ = require 'lodash'

MapGenerator = require './maps'

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

		map = @handleMap id, path, (Number level)

		map.id = id

		map

	generateConnections: (thisMap, path, level) ->
		exits = if path is 'main'
			exit: ["main-#{level+1}", 'entrance']

		for name, [map, target] of exits
			@addConnection thisMap, name, map, target

	handleMap: (map, path, level) ->
		@generateConnections map, path, level
		connections = @getConnections map

		if level is 1
			@generateStart path, level, connections

		else if level > 1
			@generateCave path, level, connections

	generateStart: (path, level, connections) ->
		MapGenerator.generateBigRoom path, level, connections, 80, 21

	generateCave: (path, level, connections) ->
		MapGenerator.generateCellularAutomata path, level, connections, 100, 50