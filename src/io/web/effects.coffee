Promise = require 'bluebird'

Effects = require '../effects'

vectorMath = require '../../vector-math'
{bresenhamLine, whilst} = require '../../util'

module.exports = class WebEffects extends Effects
	throw: ({item, start, end}) ->
		Promise.resolve null
		# @line {start, end, symbol, delay: 50}

	shootLine: ({gun, bullet, start, end}) ->
		Promise.resolve null
		# @line {start, end, symbol, delay: 50}

	shootSpread: ({gun, bullet, start, angle}) ->
		Promise.resolve null
		# angles = (angle + spread*i for i in [-1..1])

		# Promise.all (for i in [-1..1]
		# 	a = angle + spread*i

		# 	end = vectorMath.add start, {
		# 		x: Math.round range * Math.cos a
		# 		y: -Math.round range * Math.sin a
		# 	}

		# 	@line {start, end, symbol, delay: 50}
		# )

	line: ({start, end, time, delay, symbol}) ->
		Promise.resolve null
		# points = bresenhamLine start, end

		# if time? and not delay?
		# 	delay = time / points.length

		# @_performEffect {type: 'line', symbol}, (data) ->

		# 	whilst (-> points.length > 0),
		# 		=>
		# 			Promise.try =>
		# 				data.current = points.shift()
		# 				@invalidate()

		# 			.delay delay

	renderEffects: (ox, oy) ->
		for e in @effects then switch e.type
			when 'line'
				{x, y} = e.current
				@io.renderer.renderGraphicAtSlot x+ox, y+oy, e.symbol