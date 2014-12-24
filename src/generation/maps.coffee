_ = require 'lodash'

game = require '../game'
{Map} = require '../map'
{Stairs} = require '../entities'
{repeat} = require '../util'

cellAuto = require './cellular-automata'

tileAt = (map, x, y) -> map[y]?[x] ? '#'

exports.generatePos = generatePos = (w, h, data) ->
	if not h? then {w, h, data} = w

	loop
		x = game.random.range 0, w
		y = game.random.range 0, h

		break if data[y][x] isnt '#'
	{x, y}

exports.mapGen =
	border: (x,y, w,h) ->
		return '#' if not (0 < x < w-1 and 0 < y < h-1)

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

		stairs = new Stairs map, x, y
		stairs.target = {map: targetMap, position}
		stairs.down = (name is 'exit')
		
		map.addEntity stairs

exports.generateBigRoom = (path, level, connections, w, h) ->
	{border} = exports.mapGen

	map = new Map w, h

	# generate map itself ('.' everywhere, '#' surrounding entire room)
	tileCb = (a...) -> (border a...) ? '.'
	
	map.data = exports.createMapData map.w, map.h, tileCb

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
		randomFn: -> game.random.rnd()
	}

	map.data = for row, y in data
		for tile, x in row
			if tile is 1 then '#' else '.'

	exports.generateExits map, path, level, connections

	map