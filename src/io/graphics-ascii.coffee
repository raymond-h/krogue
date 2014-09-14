_ = require 'lodash'

exports.graphics = graphics =
	wall:
		symbol: '#'
		color: 'blue'
	floor: '.'

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

	_default:
		symbol: '§'
		color: 'red'

exports.get = (id = '_default') ->
	graphic = graphics[id] ? graphics._default

	if _.isString graphic
		graphic =
			symbol: graphic
			color: null

	graphic