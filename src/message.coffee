eventBus = require './event-bus'
log = require './log'

module.exports = (str) ->
	log "<GAME> #{str}"

	eventBus.emit 'log.add', str
