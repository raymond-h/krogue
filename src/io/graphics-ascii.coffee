_ = require 'lodash'

exports.graphics = graphics =
	wall: '#'
	floor: '.'

	strangeGoo: 'g'
	human: '@'
	tinyAlien: 'i'
	spaceAnemone: 'm'
	violentDonkey: 'h'

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