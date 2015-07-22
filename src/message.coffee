eventBus = require './event-bus'

module.exports = (str) ->
    eventBus.emit 'log.add', str
