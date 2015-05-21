_ = require 'lodash'

Promise = require 'bluebird'

exports.bresenhamLine = (p0, p1, callback) ->
	{x: x0, y: y0} = p0
	{x: x1, y: y1} = p1
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

exports.makePromise = exports.p = (val) ->
	Promise.resolve val

exports.whilst = (test, fn) ->
	do iteration = ->
		Promise.resolve(test())
		.then (doLoop) ->
			if doLoop
				Promise.resolve(fn())
				.then iteration

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

exports.arrayRemove = (a, item) ->
	i = a.indexOf item
	a[i..i] = [] if ~i
	i

exports.distanceSq = (o0, o1) ->
	[dx, dy] = [o1.x-o0.x, o1.y-o0.y]
	dx*dx + dy*dy

exports.distance = (o0, o1) ->
	Math.sqrt exports.distanceSq o0, o1

exports.dasherize = (className) ->
	className
	.replace /(\w)(?=[A-Z])/g, '$1-'
	.toLowerCase()

exports.repeatStr = (str, n) ->
	(new Array n+1).join str