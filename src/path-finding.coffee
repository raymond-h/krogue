_ = require 'lodash'
aStar = require 'a-star'

direction = require 'rl-directions'
vectorMath = require './vector-math'
{distance} = require './util'

offsets = [
	'up', 'down', 'left', 'right'
	'up-left', 'up-right', 'down-left', 'down-right'
].map (dir) -> direction.parse(dir)

posToStr = ({x, y}) -> "#{x};#{y}"

getNeighbouringTiles = ({x, y}, map, tileFn) ->
	if tileFn?
		result = []

		for {x: i, y: j} in offsets
			pos = {x: x+i, y: y+j}

			if tileFn(map, pos)
				result.push pos

		result

	else offsets.map ({x: i, y: j}) -> {x: x+i, y: y+j}

exports.aStar = (map, start, end, tileFn) ->
	tileFn ?= (map, {x, y}, data) ->
		not data.collidable

	opts =
		start: start
		isEnd: (node) -> node.x is end.x and node.y is end.y
		neighbor: (node) ->
			a = getNeighbouringTiles node
			.filter ({x, y}) ->
				(0 <= x < map.w and 0 <= y < map.h) and
				tileFn map, {x, y}, map.data[y][x]

			a

		distance: distance
		heuristic: (node) -> distance node, end
		hash: posToStr

	aStar opts

exports.aStarOverDistanceMap = (map, start, end, tileFn) ->
	distMap = exports.getDistanceMap map, [end], tileFn

	opts =
		start: start
		isEnd: (node) -> node.x is end.x and node.y is end.y
		neighbor: (node) -> getNeighbouringTiles node

		distance: (a, b) -> Math.max Math.abs(a.x - b.x), Math.abs(a.y - b.y)
		heuristic: ({x, y}) -> distMap[y][x]
		hash: posToStr

	aStar opts

distanceMaps = {}

exports.getDistanceMap = (map, goals, tileFn) ->
	tileFn ?= (map, {x, y}) ->
		not map.data[y]?[x].collidable

	distMaps = distanceMaps[map.id] ?= {}

	goalId = goals.map(posToStr).join '_'
	if distMaps[goalId]? then return distMaps[goalId]

	distMaps[goalId] = nodes =
		for y in [0...map.h]
			for x in [0...map.w]
				Infinity

	pending = for goal in goals
		nodes[goal.y][goal.x] = 0
		[goal, 0]

	while pending.length > 0
		[pos, dist] = pending.shift()
		calcDist = dist+1

		for {x, y} in getNeighbouringTiles pos, map, tileFn
			if nodes[y][x] > calcDist
				nodes[y][x] = calcDist
				pending.push [{x, y}, calcDist]

	nodes