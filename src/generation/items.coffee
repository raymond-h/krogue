game = require '../game'
items = require '../definitions/items'

{MapItem} = require '../entities'

exports.asMapItem = (x, y, item) ->
	new MapItem null, x, y, item

exports.generatePeculiarObject = ->
	new items.PeculiarObject

exports.generateGun = (type, name) ->
	type ?= game.random.sample ['handgun', 'shotgun']
	name ?= type

	gun = new items.Gun
	gun.name = name
	gun.gunType = type

	switch type
		when 'handgun'
			gun.range = game.random.range 5, 12

		when 'shotgun'
			gun.range = game.random.range 3, 9
			angle = game.random.range 15, 60
			gun.spread = (angle / 180 * Math.PI)

	gun

exports.generateStartingGun = ->
	type = 'handgun'

	exports.generateGun type, "trusty handgun"