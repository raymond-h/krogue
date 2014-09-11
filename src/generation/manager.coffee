_ = require 'lodash'

MapGen = require './maps'
CreatureGen = require './creatures'
ItemGen = require './items'

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

		map = @handleMap id, path, level

		map.id = id

		@handleCreatures map, path, level

		map

	generateConnections: (thisMap, path, level) ->
		exits = if path is 'main'
			exit: ["main-#{level+1}", 'entrance']

		for name, [map, target] of exits
			@addConnection thisMap, name, map, target

	handleMap: (id, path, level) ->
		@generateConnections id, path, level
		connections = @getConnections id

		if level is 1
			@generateStart path, level, connections

		else if level > 1
			@generateCave path, level, connections

	generateStart: (path, level, connections) ->
		MapGen.generateBigRoom path, level, connections, 80, 21

	generateCave: (path, level, connections) ->
		MapGen.generateCellularAutomata path, level, connections, 100, 50

	handleCreatures: (map, path, level) ->
		if level > 1
			@generateCaveCreatures map, path, level

	generateCaveCreatures: (map, path, level) ->
		creatures = for i in [1..15]
			{x, y} = MapGen.generatePos map
			CreatureGen.generateStrangeGoo x, y

		creatures.push (
			for i in [1..3]
				{x, y} = MapGen.generatePos map
				CreatureGen.generateViolentDonkey x, y
		)...

		mapItems = for i in [1..3]
			{x, y} = MapGen.generatePos map

			ItemGen.asMapItem x, y, ItemGen.generatePeculiarObject()

		{x, y} = MapGen.generatePos map
		mapItems.push (
			ItemGen.asMapItem x, y, ItemGen.generateGun()
		)

		map.addEntity creatures...
		map.addEntity mapItems...

		for i in [1..1]
			{x, y} = MapGen.generatePos map
			map.addEntity (CreatureGen.generateTinyAlien x, y)