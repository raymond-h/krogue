async = require 'async'
Q = require 'q'

exports.bresenhamLine = (x0, y0, x1, y1, callback) ->
	dx = Math.abs x1 - x0
	dy = Math.abs y1 - y0
	sx = if x0 < x1 then 1 else -1
	sy = if y0 < y1 then 1 else -1
	err = dx - dy

	loop
		break if (callback? x0, y0) is no

		break if x0 is x1 and y0 is y1

		e2 = 2 * err

		if e2 > -dx
			err -= dy
			x0 += sx

		if e2 < dy
			err += dx
			y0 += sy

		x: x0, y: y0

exports.whilst = (test, fn, callback) ->
	deferred = Q.defer()

	async.whilst test,
		(next) ->
			resolve = (a...) -> next? a...
			promise = fn resolve

			if Q.isPromiseAlike promise
				promise.nodeify next
				next = null
			
			# if fn didn't return a promise
			# then fn is presumed to call its callback sometime in the future

		deferred.makeNodeResolver()

	deferred.promise