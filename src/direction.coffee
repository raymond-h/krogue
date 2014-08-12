winston = require 'winston'
_ = require 'lodash'

directions = exports.directions =
	up: [0, -1]

	down: [0, 1]

	left: [-1, 0]

	right: [1, 0]

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
	.reduce ((p, c) -> [p[0]+c[0], p[1]+c[1]]), [0, 0]

exports.asString = (offset) ->
	dirs = while offset[0] isnt 0 or offset[1] isnt 0
		if offset[1] > 0 then offset[1]--; 'down'
		else if offset[1] < 0 then offset[1]++; 'up'
		else if offset[0] > 0 then offset[0]--; 'right'
		else if offset[0] < 0 then offset[0]++; 'left'

	dirs.join '-'

exports.getDirection = (x0, y0, x1, y1) ->
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
		when _.isArray dir and dir.length is 2
			dir.map (d) -> -d

		when _.isString dir
			exports.split dir
			.map (d) -> exports.opposites[d]
			.join '-'

		else null