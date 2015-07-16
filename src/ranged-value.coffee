module.exports = class RangedValue
	constructor: ({@min, current: @_current, @max}) ->
		@min ?= 0
		@_current ?= @max

		percentToFactor = (p) ->
			percentRegex = /^(\d+(?:\.\d*)?)%$/

			if (m = p.match? percentRegex)?
				Number (m[1] / 100)

			else Number p

		Object.defineProperties @,
			'current':
				enumerable: no
				get: => @_current
				set: (v) => @_current = v; @bound()

			'percent':
				enumerable: no
				get: => (@_current - @min) / (@max - @min)
				set: (v) =>
					@_current = (@max - @min) * (percentToFactor v) + @min
					@bound()

	empty: -> @_current <= @min
	full: -> @_current >= @max

	bound: ->
		@_current = Math.max @min, Math.min @_current, @max

	toJSON: ->
		{ @max, @min, current: @_current }