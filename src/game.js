var Game, Promise, TimeManager, _, async, eventBus, log, message, random;

async = require('async');

_ = require('lodash');

Promise = require('bluebird');

TimeManager = require('rl-time-manager');

log = require('./log');

eventBus = require('./event-bus');

message = require('./message');

random = require('./random');

require('./messages');

require('./key-handling');

Game = (function() {
  function Game() {
    this.state = 'main-menu';
    this.logs = [];
    this.mapIdCounter = 0;
    this.maps = {};
  }

  Game.prototype.generateMapId = function() {
    return "map-" + (this.mapIdCounter++);
  };

  Game.prototype.initialize = function(io) {
    this.io = io;
    log('*** Starting game...');
    this.io.initialize();
    this.io.initialized = true;
    this.renderer = this.io.renderer;
    this.effects = this.io.effects;
    this.prompts = this.io.prompts;
    return eventBus.on('key.c', (function(_this) {
      return function(ch, key) {
        if (key.ctrl) {
          return _this.quit();
        }
      };
    })(this)).on('log.add', (function(_this) {
      return function(str) {
        var results;
        _this.logs.push(str);
        results = [];
        while (_this.logs.length > 20) {
          results.push(_this.logs.shift());
        }
        return results;
      };
    })(this)).on('state.enter.game', (function(_this) {
      return function() {
        return _this.initGame();
      };
    })(this));
  };

  Game.prototype.initGame = function() {
    var GenerationManager, Player, creature, generateStartingPlayer;
    log("Init game");
    Player = require('./player');
    GenerationManager = require('./generation/manager').GenerationManager;
    this.generationManager = new GenerationManager;
    generateStartingPlayer = require('./generation/creatures').generateStartingPlayer;
    creature = generateStartingPlayer();
    this.player = new Player(creature);
    this.goTo('main-1', 'entrance');
    return eventBus.on('game.creature.dead', (function(_this) {
      return function(creature, cause) {
        if (creature.isPlayer()) {
          return _this.goState('death');
        }
      };
    })(this));
  };

  Game.prototype.quit = function() {
    if (this.io.initialized) {
      this.io.deinitialize(this);
    }
    return setTimeout((function() {
      return process.exit(0);
    }), 100);
  };

  Game.prototype.goTo = function(mapId, position) {
    var map, ref;
    map = (ref = this.maps[mapId]) != null ? ref : this.generationManager.generateMap(mapId);
    return this.transitionToMap(map, position);
  };

  Game.prototype.transitionToMap = function(map, x, y) {
    var ref;
    if (this.currentMap != null) {
      this.currentMap.removeEntity(this.player.creature);
    }
    if (map.id == null) {
      map.id = this.generateMapId();
    }
    this.maps[map.id] = map;
    this.currentMap = map;
    map.addEntity(this.player.creature);
    if (_.isString(x)) {
      ref = map.positions[x], x = ref.x, y = ref.y;
    }
    if ((x != null) && (y != null)) {
      return this.player.creature.setPos(x, y);
    }
  };

  Game.prototype.goState = function(state) {
    eventBus.emit("state.exit." + this.state, 'exit', this.state);
    this.state = state;
    return eventBus.emit("state.enter." + this.state, 'enter', this.state);
  };

  Game.prototype.main = function() {
    return async.whilst((function() {
      return true;
    }), (function(_this) {
      return function(next) {
        switch (_this.state) {
          case 'main-menu':
            return eventBus.once('key.s', function() {
              _this.goState('game');
              return next();
            });
          case 'game':
            return _this.currentMap.timeManager.tick(next);
        }
      };
    })(this), (function(_this) {
      return function(err) {
        if (err != null) {
          log.error(err.stack);
        }
        return _this.quit();
      };
    })(this));
  };

  return Game;

})();

module.exports = new Game;

module.exports.Game = Game;
