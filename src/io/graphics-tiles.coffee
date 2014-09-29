_ = require 'lodash'

exports.graphics = graphics =
	wall:
		x: 0, y: 0

	floor:
		x: 16, y: 0

	human: x: 0, y: 16
	strangeGoo: x: 16, y: 16
	spaceAnemone: x: 32, y: 16

	stairsDown: x: 32, y: 0
	stairsUp: x: 48, y: 0

	_default:
		x: 0, y: 32

exports.get = (id = '_default') ->
	graphics[id] ? graphics._default