{Entity} = require './entity'

module.exports = class MapItem extends Entity
	symbol: -> @item.symbol
	type: 'item'
	blocking: no

	constructor: (m, x, y, @item) ->
		super