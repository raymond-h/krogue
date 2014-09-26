Q = require 'q'

vectorMath = require '../vector-math'
{bresenhamLine, whilst, arrayRemove} = require '../util'

module.exports = class TtyEffects
	constructor: (@renderer) ->
		@effects = []

	doEffect: (data) ->
		Q @effects.push data

		.then =>
			switch data.type
				when 'line' then @doEffectLine data

		.then =>
			arrayRemove @effects, data
			@invalidate()

	doEffectLine: (data) ->
		{start, end, time, delay} = data

		points = bresenhamLine start, end
		
		if time? and not delay?
			delay = time / points.length

		whilst (-> points.length > 0),
			=>
				Q.fcall =>
					data.current = points.shift()
					@invalidate()

				.delay delay

	renderEffects: (x, y) ->
		c = @renderer.camera
		[ox, oy] = [x - c.x, y - c.y]

		for e in @effects
			if e.type is 'line'
				{x, y} = e.current
				@renderer.putGraphic x+ox, y+oy, e.symbol

	invalidate: -> @renderer.invalidate()