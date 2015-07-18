_ = require 'lodash'
log = require '../log'

exports.graphics = graphics =
	wall:
		symbol: '#'
		# color: '#BE5F00'
		color: '#00ff00'
		# color: 'light green'
	floor:
		symbol: '.'
		color: '#00cd00'
		# color: 'green'
		# color: '#603000'

	stairsDown: '>'
	stairsUp: '<'

	strangeGoo: 'g'
	human: '@'
	tinyAlien: 'i'
	spaceAnemone: 'm'
	violentDonkey: 'h'

	corpse: '%'
	gun: '/'
	peculiarObject: 'O'
	pokeBall: '*'

	honeycombWall:
		symbol: '#'
		color: 'yellow'

	honeycombFloor:
		symbol: '.'
		color: 'yellow'

	spaceBee: 'd'
	spaceBeeMonarch: 'Q'

	bullet: '*'

	_default:
		symbol: '§'
		color: 'red'

exports.transform = (graphic) ->
	if _.isString graphic
		symbol: graphic
		color: null

	else graphic

exports.get = (id = '_default') ->
	exports.transform (graphics[id] ? graphics._default)