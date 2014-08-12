_ = require 'lodash'
winston = require 'winston'

{Map} = require './map'
{Creature, MapItem} = require './entities'

{repeat} = require './util'

tileAt = (map, x, y) -> map[y]?[x] ? '#'

exports.mapGen =
	border: (x,y, w,h) -> return '#' if not (0 < x < w-1 and 0 < y < h-1)

	randomTiles: (random, prob) ->
		(x,y, w,h) ->
			if random() <= prob then '#' else '.'

exports.neighbourCount = (map, x, y) ->
	tiles =
		for i in [x-1..x+1]
			for j in [y-1..y+1]
				tileAt map, i, j

	(t for t in (_.flatten tiles) when t is '#').length

exports.cellularAutomataGeneration = (map, w, h, ruleFunc) ->
	tileCb = (x, y, w, h) ->
		if (ruleFunc map, x, y, (exports.neighbourCount map, x, y)) then '#' else '.'

	exports.createMapData w, h, tileCb

exports.createMapData = (w, h, tileCb) ->
	((tileCb x,y,w,h for x in [0...w]) for y in [0...h])

###
Generation functions
###
exports.generateBigRoom = (w, h) ->
	{border} = exports.mapGen

	map = new Map w, h

	# generate map itself ('.' everywhere, '#' surrounding entire room)
	tileCb = (a...) -> (border a...) ? '.'
	
	map.data = exports.createMapData map.w, map.h, tileCb

	# 'generate' entities to inhabit the map
	personality = require './personality'
	{items} = require './items'

	e = new Creature map, 12, 6
	e.speed = 30
	e.personalities.push [
		new personality.FleeFromPlayer 5
		(new personality.RandomWalk).withMultiplier 0.5
	]...

	map.entities = [
		e
		new MapItem map, 12, 4, new items['peculiar-object']
		new MapItem map, 13, 4, new items['peculiar-object']
		new MapItem map, 14, 4, new items['peculiar-object']
		new MapItem map, 15, 4, new items['peculiar-object']
	]

	map

exports.generateCellularAutomata = (w, h) ->
	{border, randomTiles} = exports.mapGen
	generation = exports.cellularAutomataGeneration

	map = new Map w, h

	initProb = 0.40
	rules = _.flatten [
		repeat 3, (..., neighbours) -> neighbours >= 5 or neighbours < 1
		repeat 2, (..., neighbours) -> neighbours >= 4
		repeat 2, (..., neighbours) -> neighbours >= 7
	]

	_randomTile = randomTiles (-> (require './game').random.rnd()), initProb

	mapData = exports.createMapData w, h,
		(a...) -> (border a...) ? (_randomTile a...)

	for rule in rules
		mapData = generation mapData, w, h, rule

	map.data = mapData

	map