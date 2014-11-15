_ = require 'lodash'

exports.graphics = graphics = require '../../public/res/tiles-def.json'

exports.get = (id = '_default') ->
	graphics[id] ? graphics._default