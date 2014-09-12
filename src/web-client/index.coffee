log = require '../log'

logLevel = 'silly'
# log.initialize logLevel, require '../io/tty-log'

log "Using log level #{logLevel}"

game = require '../game'

# game.initialize require './io/tty'
# game.main()