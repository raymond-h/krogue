_ = require 'lodash'

exports.add = (v0, v1) ->
	x: v0.x + v1.x
	y: v0.y + v1.y

exports.mult = exports.multiply = (v0, v1) ->
	if _.isNumber v1
		v1 = {x: v1, y: v1}

	x: v0.x * v1.x
	y: v0.y * v1.y

exports.div = exports.divide = (v0, v1) ->
	if _.isNumber v1
		v1 = {x: v1, y: v1}

	x: v0.x / v1.x
	y: v0.y / v1.y