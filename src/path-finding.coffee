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