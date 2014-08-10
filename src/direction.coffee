exports.directions =
	up: [0, -1]
	top: [0, -1]

	down: [0, 1]
	bottom: [0, 1]

	left: [-1, 0]

	right: [1, 0]

exports.split = (dir) ->
	dir.split /[\s\-]+/

exports.parse = (dir) ->
	exports.split dir
	.map (d) -> exports.directions[d]
	.reduce ((p, c) -> [p[0]+c[0], p[1]+c[1]]), [0, 0]

exports.asString = (offset) ->
	dirs = while offset[0] isnt 0 or offset[1] isnt 0
		if offset[0] > 0 then offset[0]--; 'right'
		else if offset[0] < 0 then offset[0]++; 'left'
		else if offset[1] > 0 then offset[1]--; 'down'
		else if offset[1] < 0 then offset[1]++; 'up'

	dirs.join '-'

exports.getDirection = (x0, y0, x1, y1) ->
	{bresenhamLine} = require './util'

	dest = (bresenhamLine x0, y0, x1, y1)[1]

	exports.asString [dest.x-x0, dest.y-y0]