Q = require 'q'

Effects = require '../effects'

vectorMath = require '../../vector-math'
{bresenhamLine, whilst} = require '../../util'

module.exports = class WebEffects extends Effects
	throw: ({start, end, symbol}) ->
		@line {start, end, symbol, delay: 50}

	shootLine: ({start, end, symbol}) ->
		@line {start, end, symbol, delay: 50}

	shootSpread: ({start, angle, spread, range, symbol}) ->
		angles = (angle + spread*i for i in [-1..1])

		Q.all (for i in [-1..1]
			a = angle + spread*i

			end = vectorMath.add start, {
				x: Math.round range * Math.cos a
				y: -Math.round range * Math.sin a
			}

			@line {start, end, symbol, delay: 50}
		)

	line: ({start, end, time, delay, symbol}) ->
		points = bresenhamLine start, end
		
		if time? and not delay?
			delay = time / points.length

		@_performEffect {type: 'line', symbol}, (data) ->
			
			whilst (-> points.length > 0),
				=>
					Q.fcall =>
						data.current = points.shift()
						@invalidate()

					.delay delay

	renderEffects: (ox, oy) ->
		for e in @effects then switch e.type
			when 'line'
				{x, y} = e.current
				@io.renderer.renderGraphicAtSlot x+ox, y+oy, e.symbol