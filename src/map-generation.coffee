_ = require 'lodash'

{Map} = require './map'
{Dummy, FastDummy} = require './creatures'

tileAt = (map, x, y) -> map[y]?[x] ? '#'

exports.randomTiles = (random, prob) -> (x,y, w,h) ->
	return '#' if not (0 < x < w-1 and 0 < y < h-1)

	if random() <= prob then '#' else '.'

exports.neighbourCount = (map, x, y) ->
	tiles =
		for i in [x-1..x+1]
			for j in [y-1..y+1]
				tileAt map, i, j

	(t for t in (_.flatten tiles) when t is '#').length

exports.cellularAutomataGeneration = (map, w, h, ruleFunc) ->
	tileCb = (x, y) ->
		if ruleFunc (exports.neighbourCount map, x, y) then '#' else '.'

	exports.createMapData w, h, tileCb

exports.createMapData = (w, h, tileCb) ->
	((tileCb x,y,w,h for x in [0...w]) for y in [0...h])

###
Generation functions
###
exports.generateBigRoom = (game, w, h) ->
	map = new Map game, w, h

	# generate map itself ('.' everywhere, '#' surrounding entire room)
	tileCb = (x,y) -> if (0 < x < w-1 and 0 < y < h-1) then '.' else '#'
	
	map.data = exports.createMapData map.w, map.h, tileCb

	# 'generate' entities to inhabit the map
	map.entities = [
		new Dummy game, map, 6, 6
		new FastDummy game, map, 12, 6
	]

	map

exports.generateCellularAutomata = (game, w, h, initProb, rules) ->
	map = new Map game, w, h

	randomFunc = -> game.random.mersenneTwister.rnd()

	mapData = exports.createMapData w, h,
		(exports.randomTiles randomFunc, initProb)

	for rule in rules
		mapData = exports.cellularAutomataGeneration mapData, w, h, rule

	map.data = mapData