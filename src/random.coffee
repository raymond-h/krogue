module.exports = class Random
	constructor: (@mersenneTwister) ->

	bool: ->
		(@mersenneTwister.int31() % 2) is 0

	rnd: -> @mersenneTwister.rnd()

	range: (min, max) ->
		@rnd() * (max - min) // 1 + min

	rangeFloat: (min, max) ->
		@rnd() * (max - min) + min

	chance: (chance) ->
		@rnd() < chance

	direction: (n, diagonal = no) ->
		choices = switch n
			when 4
				if diagonal then [
					'up-left', 'up-right'
					'down-left', 'down-right'
				]

				else ['up', 'down', 'left', 'right']

			when 8 then [
				'up-left', 'up-right'
				'down-left', 'down-right'
				'up', 'down', 'left', 'right'
			]

		@sample choices

	sample: (a, n) ->
		if not n? then a[@range 0, a.length]

		else @shuffle(a[..])[...n]

	shuffle: (a) ->
		for i in [0...a.length]
			j = @range i, a.length
			[ a[i], a[j] ] = [ a[j], a[i] ]
		a

	unitCirclePoint: ->
		t = 2*Math.PI * @rnd()
		r = Math.sqrt @rnd()
		[r * Math.cos(t), r * Math.sin(t)]

	gaussian: (mean = 0, stdev = 1) ->
		[x, y] = @unitCirclePoint()
		s = x*x + y*y

		c = Math.sqrt(-2 * Math.log(s) / s)
		[x*c, y*c].map (v) -> stdev * v + mean