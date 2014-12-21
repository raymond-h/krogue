Q = require 'q'

Effects = require '../effects'

vectorMath = require '../../vector-math'
{bresenhamLine, whilst} = require '../../util'

module.exports = class TtyEffects extends Effects
	throw: ({start, end, symbol}) ->
		@line {start, end, symbol, delay: 50}

	shootLine: ({start, end, symbol}) ->
		@line {start, end, symbol, delay: 50}

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

	renderEffects: (x, y) ->
		c = @io.renderer.camera
		[ox, oy] = [x - c.x, y - c.y]

		for e in @effects then switch e.type
			when 'line'
				{x, y} = e.current
				@io.renderer.putGraphic x+ox, y+oy, e.symbol