async = require 'async'
Q = require 'q'
_ = require 'lodash'

exports.bresenhamLine = (x0, y0, x1, y1, callback) ->
	dx = Math.abs x1 - x0
	dy = Math.abs y1 - y0
	sx = if x0 < x1 then 1 else -1
	sy = if y0 < y1 then 1 else -1
	err = dx - dy

	if not callback?
		result = []
		callback = (x, y) -> result.push {x, y}

	loop
		break if (callback x0, y0) is no

		break if x0 is x1 and y0 is y1

		e2 = 2 * err

		if e2 > -dx
			err -= dy
			x0 += sx

		if e2 < dy
			err += dx
			y0 += sy

	result

exports.whilst = (test, fn, callback) ->
	Q.ninvoke async, 'whilst',
		test,
		((next) -> fn().nodeify next)

	.nodeify callback

exports.edge = (r, edge) ->
	switch edge
		when 'left' then r.x
		when 'right' then r.x+r.w
		when 'top', 'up' then r.y
		when 'bottom', 'down' then r.y+r.h

exports.snapToRange = (min, curr, max) ->
	Math.max min, Math.min curr, max

exports.repeat = (n, item) ->
	item for i in [1..n]