Promise = require 'bluebird'

Effects = require '../effects'

vectorMath = require '../../vector-math'
log = require '../../log'
{bresenhamLine, whilst} = require '../../util'

module.exports = class TtyEffects extends Effects
	throw: ({item, start, end}) ->
		symbol = @io.renderer.getGraphic item
		@line {start, end, symbol, delay: 50}

	shootLine: ({gun, bullet, start, end}) ->
		symbol = @io.renderer.getGraphic bullet
		@line {start, end, symbol, delay: 50}

	shootSpread: ({gun, bullet, start, angle}) ->
		{spread, range} = gun
		symbol = @io.renderer.getGraphic bullet

		angles = (angle + spread*i for i in [-1..1])

		Promise.all (for i in [-1..1]
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
					Promise.try =>
						data.current = points.shift()
						@invalidate()

					.delay delay

	renderEffects: (x, y) ->
		c = @io.renderer.camera
		[ox, oy] = [x - c.x, y - c.y]

		for e in @effects then switch e.type
			when 'line'
				{x, y} = e.current
				@io.renderer.bufferPut x+ox, y+oy, e.symbol