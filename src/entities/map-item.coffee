{Entity} = require './entity'

module.exports = class MapItem extends Entity
	symbol: -> @item.symbol
	type: 'item'

	constructor: (m, x, y, @item) ->
		super

	loadFromJSON: ->
		super

		items = require '../items'

		@item = items.fromJSON @item

		@