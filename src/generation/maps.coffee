_ = require 'lodash'

random = require '../random'
{Map} = require '../map'
{Stairs} = require '../entities'
{repeat} = require '../util'

cellAuto = require './cellular-automata'

exports.generatePos = generatePos = (w, h, data) ->
	if not h? then {w, h, data} = w

	loop
		x = random.range 0, w
		y = random.range 0, h

		break if not (data[y][x].collidable ? no)
	{x, y}

exports.createMapData = (w, h, tileCb) ->
	((tileCb x,y,w,h for x in [0...w]) for y in [0...h])

###
Generation functions
###
exports.generateExits = (map, path, level, connections) ->
	# exits and entrances (incl. stairs)
	map.positions =
		'entrance': generatePos map
		'exit': generatePos map

	for name, [targetMap, position] of connections
		{x, y} = map.positions[name] ? generatePos map

		stairs = new Stairs {map, x, y}
		stairs.target = {map: targetMap, position}
		stairs.down = (name is 'exit')

		map.addEntity stairs

exports.generateBigRoom = (path, level, connections, w, h) ->
	map = new Map w, h

	# generate map itself ('.' everywhere, '#' surrounding entire room)
	tileCb = (x, y, w, h) ->
		if not (0 < x < w-1 and 0 < y < h-1) then 1 else 0

	data = exports.createMapData map.w, map.h, tileCb

	map.data = convertMapData data, [
		{ collidable: no, seeThrough: yes, type: 'floor' }
		{ collidable: yes, seeThrough: no, type: 'wall' }
	]

	exports.generateExits map, path, level, connections

	map

exports.generateCellularAutomata = (path, level, connections, w, h) ->
	map = new Map w, h

	initProb = 0.44
	rules = _.flatten [
		repeat 6, (..., neighbours) -> neighbours >= 5
		repeat 3, (..., neighbours) -> neighbours >= 4
	]

	data = cellAuto.createMap {
		width: w, height: h
		initProbability: initProb
		rules
		randomFn: -> random.rnd()
	}

	map.data = convertMapData data, [
		{ collidable: no, seeThrough: yes, type: 'floor' }
		{ collidable: yes, seeThrough: no, type: 'wall' }
	]

	exports.generateExits map, path, level, connections

	map

recursiveMap = (data, fn) ->
	map = (a...) -> if _.isArray a[0] then a[0].map map else fn a...

	data.map map

convertMapData = (data, values) ->
	recursiveMap data, (v) ->
		switch
			when _.isArray values then values[v]
			when _.isFunction values then values v
