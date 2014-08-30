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

ownProps = (obj) ->
	r = {}
	for own k, v of obj
		r[k] = v
	r

toJSON = (obj) ->
	traverse(obj).map (x) ->
		if x? and (not _.isPlainObject x) and x._type?
			json = x.toJSON?() ? ownProps x
			json._type = x._type
			@update json

loadFromJSON = (obj, json) ->
	defLoad = ->
		_.assign obj, _.omit json, '_type'

	if obj.loadFromJSON?
		obj.loadFromJSON json, defLoad

	else defLoad()

exports.save = (game, filename) ->
	filename = path.join 'saves', filename

	mkdirp.sync 'saves'
	fs.writeFileSync filename, JSON.stringify toJSON game.saveToJSON()

exports.load = (game, filename) ->
	filename = path.join 'saves', filename

	reviver = (k, v) ->
		return v if k is ''

		if (_.isPlainObject v) and v._type?
			Clazz = classManager.get v._type

			o = new Clazz
			loadFromJSON o, v
			o

		else v

	json = JSON.parse (fs.readFileSync filename, encoding: 'utf-8'), reviver

	game.loadFromJSON json