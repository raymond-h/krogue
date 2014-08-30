_ = require 'lodash'

class Hello
class World
class Marvel
class What

classNames = {}

addClass = (v, namespace = '') ->
	typeName = "#{namespace}#{v.name}"
	classNames[typeName] = v
	v::typeName = typeName

addClasses = (classes, namespace = '') ->
	for k, v of classes
		if _.isFunction v
			addClass v, namespace

		else addClasses v, "#{namespace}#{k}::"

addClasses {
	'item': {
		Hello
		World
	}

	'boat': {
		Marvel
	}

	What
}

console.log classNames
console.log (new Marvel).typeName
console.log classNames['boat::Marvel']