var Promise, Prompts, WebPrompts, _, direction, eventBus, ref, snapToRange, vectorMath, whilst,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  slice = [].slice;

Promise = require('bluebird');

_ = require('lodash');

ref = require('../../util'), whilst = ref.whilst, snapToRange = ref.snapToRange;

eventBus = require('../../event-bus');

direction = require('rl-directions');

vectorMath = require('../../vector-math');

Prompts = require('../prompts');

module.exports = WebPrompts = (function(superClass) {
  extend(WebPrompts, superClass);

  function WebPrompts() {
    return WebPrompts.__super__.constructor.apply(this, arguments);
  }

  WebPrompts.prototype.list = function(header, choices, opts) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var _choices, cancel, choicePicked, i, items, mapDisplayed, v;
        _choices = (function() {
          var j, len, ref1, ref2, results;
          results = [];
          for (i = j = 0, len = choices.length; j < len; i = ++j) {
            v = choices[i];
            results.push({
              key: (ref1 = v != null ? v.key : void 0) != null ? ref1 : this.listOptions[i],
              name: _.isString(v) ? v : (ref2 = v.name) != null ? ref2 : '???',
              orig: v,
              index: i
            });
          }
          return results;
        }).call(_this);
        choicePicked = function(index) {
          var choice;
          _this.game.renderer.hideMenu();
          choice = _choices[index];
          return resolve({
            key: choice.key,
            value: choices[index],
            index: index
          });
        };
        cancel = function() {
          _this.game.renderer.hideMenu();
          return resolve(null);
        };
        items = (function() {
          var j, len, results;
          results = [];
          for (j = 0, len = _choices.length; j < len; j++) {
            v = _choices[j];
            results.push(v.key + ". " + v.name);
          }
          return results;
        })();
        _this.game.renderer.showSingleChoiceMenu(header, items, {
          onChoice: choicePicked,
          onCancel: cancel
        });
        mapDisplayed = _.zipObject((function() {
          var j, len, results;
          results = [];
          for (j = 0, len = _choices.length; j < len; j++) {
            v = _choices[j];
            results.push([this.pressedKey(v.key), v.index]);
          }
          return results;
        }).call(_this));
        return _this.keys(null, ['escape'].concat(slice.call(_.keys(mapDisplayed)))).then(function(key) {
          if (key === 'escape') {
            return cancel();
          }
          return choicePicked(mapDisplayed[key]);
        });
      };
    })(this));
  };

  WebPrompts.prototype.multichoiceList = function(header, choices, opts) {
    var stopped;
    stopped = false;
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var _choices, callbackDone, cancel, done, i, items, mapDisplayed, ref1, updateChecked, v;
        _choices = (function() {
          var j, len, ref1, ref2, results;
          results = [];
          for (i = j = 0, len = choices.length; j < len; i = ++j) {
            v = choices[i];
            results.push({
              key: (ref1 = v.key) != null ? ref1 : this.listOptions[i],
              name: _.isString(v) ? v : (ref2 = v.name) != null ? ref2 : '???',
              orig: v,
              index: i,
              checked: false
            });
          }
          return results;
        }).call(_this);
        done = function(indices) {
          var finalChoices;
          stopped = true;
          _this.game.renderer.hideMenu();
          finalChoices = indices.map(function(index) {
            var choice;
            choice = _choices[index];
            return {
              key: choice.key,
              value: choices[index],
              index: index
            };
          });
          return resolve(finalChoices);
        };
        cancel = function() {
          stopped = true;
          _this.game.renderer.hideMenu();
          return resolve(null);
        };
        items = (function() {
          var j, len, results;
          results = [];
          for (j = 0, len = _choices.length; j < len; j++) {
            v = _choices[j];
            results.push(v.key + ". " + v.name);
          }
          return results;
        })();
        ref1 = _this.game.renderer.showMultiChoiceMenu(header, items, {
          onDone: done,
          onCancel: cancel
        }), updateChecked = ref1[0], callbackDone = ref1[1];
        mapDisplayed = _.zipObject((function() {
          var j, len, results;
          results = [];
          for (j = 0, len = _choices.length; j < len; j++) {
            v = _choices[j];
            results.push([this.pressedKey(v.key), v.index]);
          }
          return results;
        }).call(_this));
        return whilst((function() {
          return !stopped;
        }), function() {
          return _this.keys(null, ['escape', 'enter'].concat(slice.call(_.keys(mapDisplayed)))).then(function(key) {
            if (stopped) {
              return;
            }
            if (key === 'escape') {
              return cancel();
            }
            if (key === 'enter') {
              return callbackDone();
            }
            return updateChecked(mapDisplayed[key]);
          });
        });
      };
    })(this));
  };

  WebPrompts.prototype.position = function(message, opts) {
    var pos, ref1, ref2, ref3, ref4, snapPos, updatePos;
    if (opts == null) {
      opts = {};
    }
    this.game.renderer.setPromptMessage(message);
    pos = null;
    snapPos = (function(_this) {
      return function() {
        pos.x = snapToRange(0, pos.x, _this.game.currentMap.w - 1);
        return pos.y = snapToRange(0, pos.y, _this.game.currentMap.h - 1);
      };
    })(this);
    updatePos = (function(_this) {
      return function(newPos) {
        pos = newPos;
        snapPos();
        if (typeof opts.progress === "function") {
          opts.progress(pos);
        }
        _this.game.renderer.cursor = pos;
        return _this.game.renderer.invalidate();
      };
    })(this);
    updatePos({
      x: (ref1 = (ref2 = opts["default"]) != null ? ref2.x : void 0) != null ? ref1 : 0,
      y: (ref3 = (ref4 = opts["default"]) != null ? ref4.y : void 0) != null ? ref3 : 0
    });
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var done, e, handler, j, len, ref5, unbindClick;
        unbindClick = _this.game.renderer.onClick(function(e) {
          if (pos.x === e.world.x && pos.y === e.world.y) {
            return done(false);
          } else {
            return updatePos(e.world);
          }
        });
        handler = function(action, dir) {
          switch (this.event) {
            case 'key.escape':
              return done(true);
            case 'key.enter':
              return done(false);
            default:
              if (action === 'direction') {
                return updatePos(vectorMath.add(pos, direction.parse(dir)));
              }
          }
        };
        ref5 = ['key.escape', 'key.enter', 'action.**'];
        for (j = 0, len = ref5.length; j < len; j++) {
          e = ref5[j];
          eventBus.on(e, handler);
        }
        return done = function(cancelled) {
          var k, len1, ref6;
          unbindClick();
          ref6 = ['key.escape', 'key.enter', 'action.**'];
          for (k = 0, len1 = ref6.length; k < len1; k++) {
            e = ref6[k];
            eventBus.off(e, handler);
          }
          _this.game.renderer.cursor = null;
          _this.game.renderer.invalidate();
          return resolve(!cancelled ? pos : null);
        };
      };
    })(this));
  };

  return WebPrompts;

})(Prompts);
