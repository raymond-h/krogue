_ = require 'lodash'
traverse = require 'traverse'

class ClassManager
	constructor: ->
		@classNames = {}

	get: (name) -> @classNames[name]
	type: (obj) -> obj._type

	add: (classes, namespace = '') ->
		for k, v of classes
			if _.isFunction v
				name = "#{namespace}#{k}"
				@classNames[name] = v
				v::_type = name

			else if k[0] isnt '_'
				@add v, "#{namespace}#{k}::"

classManager = new ClassManager

{Map} = require './map'

classManager.add {
	items: require './definitions/items'
	species: require './definitions/creature-species'
	personalities: require './definitions/personalities'
	entities: require './entities'

	Map
}

## Serialization (to string)
toJSON = (obj) ->
	json = obj.toJSON?() ?
		_.pick obj, (v,k,o) -> _.has o,k

	json._type = obj._type
	json

transform = (obj) ->
	traverse(obj).map (x) ->
		if x? and (not _.isPlainObject x) and x._type?
			@update toJSON x

stringify = (obj) ->
	JSON.stringify transform obj

## Deserialization (from string)
loadFromJSON = (obj, json) ->
	defLoad = ->
		_.assign obj, _.omit json, '_type'

	if obj.loadFromJSON?
		obj.loadFromJSON json, defLoad

	else defLoad()

reviver = (k, v) ->
	if (_.isPlainObject v) and v._type?
		Clazz = classManager.get v._type

		o = new Clazz
		loadFromJSON o, v
		o

	else v

parse = (json) ->
	JSON.parse json, reviver

## Exports
module.exports = {
	toJSON, transform, stringify
	loadFromJSON, reviver, parse
}