module.exports = class Random
	constructor: (@mersenneTwister) ->

	bool: ->
		(@mersenneTwister.int31() % 2) is 0

	int: (min, max) ->
		@mersenneTwister.random() * (max - min) // 1 + min

	sample: (a, n) ->
		if n? then a[int 0, a.length]

		else shuffle(a[..])[...n]

	shuffle: (a) ->
		for i in [0...a.length]
			j = @int i, a.length
			[ a[i], a[j] ] = [ a[j], a[i] ]
		a