fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'

_ = require 'lodash'
winston = require 'winston'
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

			else @add v, "#{namespace}#{k}::"

classManager = new ClassManager

{Map} = require './map'

classManager.add {
	items: require './definitions/items'
	species: require './definitions/creature-species'
	personalities: require './definitions/personalities'
	entities: require './entities'

	Map
}

toJSON = (obj) ->
	json = obj.toJSON?() ?
		_.pick obj, (v,k,o) -> _.has o,k

	json._type = obj._type
	json

loadFromJSON = (obj, json) ->
	defLoad = ->
		_.assign obj, _.omit json, '_type'

	if obj.loadFromJSON?
		obj.loadFromJSON json, defLoad

	else defLoad()

exports.save = (game, filename) ->
	filename = path.join 'saves', filename
	mkdirp.sync 'saves'

	transform = (obj) ->
		traverse(obj).map (x) ->
			if x? and (not _.isPlainObject x) and x._type?
				@update toJSON x

	fs.writeFileSync filename, JSON.stringify transform game.saveToJSON()

exports.load = (game, filename) ->
	filename = path.join 'saves', filename

	reviver = (k, v) ->
		if (_.isPlainObject v) and v._type?
			Clazz = classManager.get v._type

			o = new Clazz
			loadFromJSON o, v
			o

		else v

	json = JSON.parse (fs.readFileSync filename, encoding: 'utf-8'), reviver

	game.loadFromJSON json