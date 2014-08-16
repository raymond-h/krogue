winston = require 'winston'
_ = require 'lodash'

directions = exports.directions =
	up: {x: 0, y: -1}

	down: {x: 0, y: 1}

	left: {x: -1, y: 0}

	right: {x: 1, y: 0}

aliases = exports.aliases =
	top: 'up'
	bottom: 'down'

exports.opposites =
	left: 'right'
	up: 'down'
	top: 'bottom'

_.assign exports.opposites, _.invert exports.opposites

exports.split = (dir) ->
	dir.split /[\s\-]+/

exports.parse = (dir) ->
	exports.split dir
	.map (d) -> directions[d] ? directions[aliases[d]]
	.reduce ((p, c) -> x: p.x+c.x, y: p.y+c.y), {x: 0, y: 0}

exports.asString = (offset) ->
	dirs = while offset.x isnt 0 or offset.y isnt 0
		if offset.y > 0 then offset.y--; 'down'
		else if offset.y < 0 then offset.y++; 'up'
		else if offset.x > 0 then offset.x--; 'right'
		else if offset.x < 0 then offset.x++; 'left'

	dirs.join '-'

exports.normalize = (dir, maxDist = 1) ->
	{snapToRange} = require './util'

	o = exports.parse dir
	exports.asString
		x: (snapToRange -maxDist, o.x, maxDist)
		y: (snapToRange -maxDist, o.y, maxDist)

exports.getDirection = (p0, p1) ->
	{x: x0, y: y0} = p0
	{x: x1, y: y1} = p1
	# y1 is sub. from y0, but x0 is sub. from x1.
	# atan has positive Y be up, but in-game
	# positive Y is down, so it needs to be inverted

	exports.radToDirection Math.atan2 y0-y1, x1-x0

exports.radToDirection = (angle) ->
	angle /= Math.PI # radians to a factor
	while angle < 0 then angle += 2
	while angle > 2 then angle -= 2

	# right is added twice, so 1.875 <= angle < 2 gets handled properly
	angles = [
		'right'
		'up-right'
		'up'
		'up-left'
		'left'
		'down-left'
		'down'
		'down-right'
		'right'
	]

	for a in angles
		return a if (-0.125 <= angle < 0.125)

		angle -= 2/8

exports.opposite = (dir) ->
	switch
		when dir.x? and dir.y?
			x: -dir.x, y: -dir.y

		when _.isString dir
			exports.split dir
			.map (d) -> exports.opposites[d]
			.join '-'

		else null