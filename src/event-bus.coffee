{EventEmitter2} = require 'eventemitter2'
Promise = require 'bluebird'

class EventBus extends EventEmitter2
	constructor: ->
		super { wildcard: yes, newListener: no }

	waitOn: (event) ->
		(
			new Promise (resolve, reject) =>
				@once event, (params...) ->
					resolve params
		)
		.cancellable()

module.exports = exports = new EventBus
exports.EventBus = EventBus

log = require './log'

exports.onAny (a...) ->
	log.silly "Event: '#{@event}'; ", a
