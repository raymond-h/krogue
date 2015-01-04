aStar = require 'a-star'

direction = require './direction'
vectorMath = require './vector-math'
{distance} = require './util'

exports.aStar = (map, start, end, tileFn) ->
	tileFn ?= (map, {x, y}, data) ->
		not data.collidable

	opts =
		start: start
		isEnd: (node) -> node.x is end.x and node.y is end.y
		neighbor: (node) ->
			a = [
				'up', 'down', 'left', 'right'
				'up-left', 'up-right', 'down-left', 'down-right'
			]
			.map (dir) -> vectorMath.add node, direction.parse(dir)
			.filter ({x, y}) ->
				(0 <= x < map.w and 0 <= y < map.h) and
				tileFn map, {x, y}, map.data[y][x]

			a

		distance: distance
		heuristic: (node) -> distance node, end
		hash: ({x, y}) -> "#{x};#{y}"

	aStar opts

distanceMaps = {}

exports.getDistanceMap = (map, goals, tileFn) ->
	tileFn ?= (map, {x, y}, data) ->
		not data.collidable

	goals = goals.map ({x, y}) -> "#{x};#{y}"
	goalId = goals.join '_'

	distMaps = distanceMaps[map.id] ?= {}

	if distMaps[goalId]? then return distMap

	distMaps[goalId] = distMap =
		for y in [0...map.h]
			for x in [0...map.w]
				if "#{x};#{y}" in goals then 0 else Infinity

	smallestNeighbour = (ox, oy) ->
		smallest = Infinity

		for i in [-1..1]
			for j in [-1..1]
				smallest = Math.min smallest, (distMap[i + oy]?[j + ox]) ? Infinity

		smallest

	iteration = ->
		changedOccured = no

		for x in [0...map.w]
			for y in [0...map.h]
				if not tileFn map, {x, y}, map.data[y]?[x]
					continue

				smallest = smallestNeighbour x, y

				if distMap[y][x] > smallest+2
					distMap[y][x] = smallest+1

					changedOccured = yes

		changedOccured

	while iteration() then

	distMap