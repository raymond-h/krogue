var Player, Promise, Stairs, _, direction, eventBus, game, log, message, p, prompts, random, vectorMath, whilst,
  slice = [].slice;

Promise = require('bluebird');

_ = require('lodash');

game = require('./game');

random = require('./random');

eventBus = require('./event-bus');

message = require('./message');

log = require('./log');

Stairs = require('./entities').Stairs;

direction = require('rl-directions');

vectorMath = require('./vector-math');

whilst = require('./util').whilst;

prompts = game.prompts;

p = require('./util').p;

module.exports = Player = (function() {
  function Player(creature) {
    this.creature = creature;
    Object.defineProperty(this, 'lookPos', {
      enumerable: false,
      get: (function(_this) {
        return function() {
          var ref;
          return (ref = _this._lookPos) != null ? ref : _this.creature;
        };
      })(this),
      set: (function(_this) {
        return function(pos) {
          return _this._lookPos = pos;
        };
      })(this)
    });
    this._lookPos = null;
  }

  Player.prototype.tick = function() {
    eventBus.emit('turn.player.start');
    return whilst((function() {
      return game.renderer.hasMoreLogs();
    }), function() {
      return prompts.actions(null, ['more-logs']).then(function() {
        return game.renderer.showMoreLogs();
      });
    }).then(function() {
      return eventBus.waitOn('action.**');
    }).then((function(_this) {
      return function(arg) {
        var action, params;
        action = arg[0], params = 2 <= arg.length ? slice.call(arg, 1) : [];
        return _this.doAction.apply(_this, [action].concat(slice.call(params)));
      };
    })(this)).then(function(cost) {
      if (!_.isNumber(cost)) {
        cost = 0;
      }
      return eventBus.emit('turn.player.end');
    });
  };

  Player.prototype.doAction = function() {
    var action, choices, equips, handler, i, inventory, items, map, nextEntity, params, position, ref, ref1, reloadableItems, s, skills, stairs;
    action = arguments[0], params = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    switch (action) {
      case 'idle':
        return 12;
      case 'direction':
        if (this.creature.move(params[0])) {
          return 12;
        } else {
          return 0;
        }
        break;
      case 'possess':
        nextEntity = function(map) {
          var entities;
          entities = map.entities;
          entities.push(entities.shift());
          if (entities[0].type === 'creature') {
            return entities[0];
          } else {
            return nextEntity(map);
          }
        };
        return this.creature = nextEntity(this.creature.map);
      case 'inventory':
        choices = slice.call((function() {
            var j, len, ref, results;
            ref = this.creature.equipment;
            results = [];
            for (j = 0, len = ref.length; j < len; j++) {
              i = ref[j];
              results.push(i.name + " (" + (i.equipSlotUseString(this.creature)) + ")");
            }
            return results;
          }).call(this)).concat(slice.call((function() {
            var j, len, ref, results;
            ref = this.creature.inventory;
            results = [];
            for (j = 0, len = ref.length; j < len; j++) {
              i = ref[j];
              results.push(i.name);
            }
            return results;
          }).call(this)));
        return prompts.list('Inventory', choices).then(function(choice) {
          var key, value;
          if (choice == null) {
            return message('Never mind.');
          }
          key = choice.key, value = choice.value;
          return message("You picked " + key + ": " + value + "!");
        });
      case 'look':
        handler = (function(_this) {
          return function(pos) {
            return _this._lookPos = pos;
          };
        })(this);
        return prompts.position(null, {
          "default": this.creature,
          progress: handler
        }).then((function(_this) {
          return function(pos) {
            _this._lookPos = null;
            return 0;
          };
        })(this));
      case 'equip':
        return prompts.list('Equip which item?', this.creature.inventory).then((function(_this) {
          return function(choice) {
            var item;
            if (choice == null) {
              return message('Never mind.');
            }
            item = choice.value;
            if (_this.creature.equip(item)) {
              return 6;
            } else {
              return message("If you do that, you're gonna overburden yourself. So don't do that.");
            }
          };
        })(this));
      case 'unequip':
        equips = (function() {
          var ref, results;
          ref = this.creature.equipment;
          results = [];
          for (s in ref) {
            i = ref[s];
            results.push({
              item: i,
              name: i.name + " (" + (i.equipSlotUseString(this.creature)) + ")"
            });
          }
          return results;
        }).call(this);
        return prompts.list('Put away which item?', equips).then((function(_this) {
          return function(choice) {
            if (choice == null) {
              return message('Never mind.');
            }
            _this.creature.unequip(choice.value.item);
            return 6;
          };
        })(this));
      case 'reload':
        equips = (function() {
          var ref, results;
          ref = this.creature.equipment;
          results = [];
          for (s in ref) {
            i = ref[s];
            results.push({
              item: i,
              name: i.name + " (" + (i.equipSlotUseString(this.creature)) + ")"
            });
          }
          return results;
        }).call(this);
        inventory = (function() {
          var j, len, ref, results;
          ref = this.creature.inventory;
          results = [];
          for (j = 0, len = ref.length; j < len; j++) {
            i = ref[j];
            results.push({
              item: i,
              name: i.name
            });
          }
          return results;
        }).call(this);
        reloadableItems = slice.call(equips).concat(slice.call(inventory)).filter(function(v) {
          return v.item.reload != null;
        });
        return prompts.list('Reload which item?', reloadableItems).then((function(_this) {
          return function(choice) {
            var invWithoutPicked, reloadItem;
            if (choice == null) {
              return message('Never mind.');
            }
            reloadItem = choice.value.item;
            invWithoutPicked = inventory.filter(function(v) {
              return v.item !== reloadItem;
            });
            return prompts.list('Reload with which item?', invWithoutPicked).then(function(choice) {
              var ammo, oldReloadItemName;
              if (choice == null) {
                return message('Never mind.');
              }
              ammo = choice.value.item;
              oldReloadItemName = reloadItem.name;
              if (reloadItem.reload(ammo)) {
                _.pull(_this.creature.inventory, ammo);
                return message("Loaded " + oldReloadItemName + " with " + ammo.name + " - rock and roll!");
              } else {
                return message("Dangit! Can't fit " + ammo.name + " into " + oldReloadItemName + ", it seems...");
              }
            });
          };
        })(this));
      case 'pickup':
        items = this.creature.map.entitiesAt(this.creature.x, this.creature.y, 'item');
        switch (items.length) {
          case 0:
            return message('There, frankly, is nothing here!');
          case 1:
            this.creature.pickup(items[0]);
            return 3;
          default:
            return prompts.multichoiceList('Pick up which item?', (function() {
              var j, len, results;
              results = [];
              for (j = 0, len = items.length; j < len; j++) {
                i = items[j];
                results.push("" + i.item.name);
              }
              return results;
            })()).then((function(_this) {
              return function(choices) {
                var c, j, len;
                if (choices == null) {
                  return message('Never mind.');
                }
                for (j = 0, len = choices.length; j < len; j++) {
                  c = choices[j];
                  _this.creature.pickup(items[c.index]);
                }
                return 3 * choices.length;
              };
            })(this));
        }
        break;
      case 'drop':
        if (this.creature.inventory.length === 0) {
          return message('You empty your empty inventory onto the ground.');
        } else {
          return prompts.multichoiceList('Drop which item?', this.creature.inventory).then((function(_this) {
            return function(choices) {
              var c, j, len;
              if (choices == null) {
                return message('Never mind.');
              }
              for (j = 0, len = choices.length; j < len; j++) {
                c = choices[j];
                _this.creature.drop(c.value);
              }
              return 3 * choices.length;
            };
          })(this));
        }
        break;
      case 'fire':
        return prompts.position('Fire where?', {
          "default": this.creature
        }).then((function(_this) {
          return function(pos) {
            var item, offset;
            offset = vectorMath.sub(pos, _this.creature);
            item = random.sample(_this.creature.getItemsForSlot('hand'));
            if (item == null) {
              message('Your hand is surprisingly bad at firing bullets.');
              return 2;
            } else if (item.fire == null) {
              message("You find the lack of bullets from your " + item.name + " disturbing.");
              return 2;
            } else {
              return p(item.fire(_this.creature, offset)).then(function() {
                return 6;
              });
            }
          };
        })(this));
      case 'attack':
        return prompts.direction('Attack in what direction?').then((function(_this) {
          return function(dir) {
            _this.creature.attack(dir);
            return 12;
          };
        })(this));
      case 'throw':
        return prompts.list('Throw which item?', this.creature.inventory).then((function(_this) {
          return function(choice) {
            var item;
            if (choice == null) {
              return message('Never mind.');
            }
            item = choice.value;
            return prompts.position('Throw where?', {
              "default": _this.creature
            }).then(function(pos) {
              var offset;
              if (pos == null) {
                return message('Never mind.');
              }
              offset = vectorMath.sub(pos, _this.creature);
              return p(_this.creature["throw"](item, offset)).then(function() {
                return 6;
              });
            });
          };
        })(this));
      case 'use-skill':
        skills = this.creature.skills();
        if (skills.length === 0) {
          message("You really don't have the skills to do that. Get better.");
          return;
        }
        return prompts.list('Use which skill?', skills).then((function(_this) {
          return function(choice) {
            var skill;
            if (choice == null) {
              return message('Never mind.');
            }
            skill = choice.value;
            return p((function() {
              if (skill.askParams == null) {
                return null;
              }
              return skill.askParams(_this.creature);
            })()).then(function(params) {
              return skill.use(_this.creature, params);
            });
          };
        })(this));
      case 'test-dir':
        return prompts.direction('Pick a direction!', {
          cancelable: true
        }).then(function(dir) {
          return message("You answered: " + dir);
        });
      case 'test-yn':
        return prompts.yesNo('Are you sure?', {
          cancelable: true
        }).then(function(reply) {
          return message("You answered: " + reply);
        });
      case 'test-multi':
        choices = ['apples', 'bananas', 'oranges'];
        return prompts.multichoiceList('Pick any fruits!', choices).then(function(choices) {
          if (choices == null) {
            return message('Cancelled.');
          }
          choices = choices.map(function(c) {
            return c.value;
          });
          if (choices.length > 0) {
            return message("You picked: " + (choices.join(', ')));
          } else {
            return message('You picked none!!');
          }
        });
      case 'down-stairs':
        stairs = this.creature.map.entitiesAt(this.creature.x, this.creature.y, function(e) {
          return e.type === 'stairs' && e.down;
        })[0];
        if (stairs != null) {
          ref = stairs.target, map = ref.map, position = ref.position;
          return game.goTo(map, position);
        }
        break;
      case 'up-stairs':
        stairs = this.creature.map.entitiesAt(this.creature.x, this.creature.y, function(e) {
          return e.type === 'stairs' && !e.down;
        })[0];
        if (stairs != null) {
          ref1 = stairs.target, map = ref1.map, position = ref1.position;
          return game.goTo(map, position);
        }
        break;
      case 'test-pos':
        return prompts.position('Test position!', {
          "default": this.creature
        }).then(function(pos) {
          if (pos != null) {
            message("You picked position: " + pos.x + "," + pos.y);
          }
          if (pos == null) {
            return message("Never mind.");
          }
        });
    }
  };

  return Player;

})();
