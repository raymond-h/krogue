var Prompts, TtyPrompts, _, direction, ref, snapToRange, vectorMath, whilst,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  slice = [].slice;

_ = require('lodash');

ref = require('../../util'), whilst = ref.whilst, snapToRange = ref.snapToRange;

direction = require('rl-directions');

vectorMath = require('../../vector-math');

Prompts = require('../prompts');

module.exports = TtyPrompts = (function(superClass) {
  extend(TtyPrompts, superClass);

  function TtyPrompts() {
    return TtyPrompts.__super__.constructor.apply(this, arguments);
  }

  TtyPrompts.prototype.list = function(header, choices, opts) {
    var _choices, i, mapDisplayed, v;
    _choices = (function() {
      var j, len, ref1, ref2, results;
      results = [];
      for (i = j = 0, len = choices.length; j < len; i = ++j) {
        v = choices[i];
        results.push({
          key: (ref1 = v.key) != null ? ref1 : this.listOptions[i],
          name: _.isString(v) ? v : (ref2 = v.name) != null ? ref2 : '???',
          orig: v,
          index: i
        });
      }
      return results;
    }).call(this);
    mapDisplayed = _.zipObject((function() {
      var j, len, results;
      results = [];
      for (j = 0, len = _choices.length; j < len; j++) {
        v = _choices[j];
        results.push([this.pressedKey(v.key), v]);
      }
      return results;
    }).call(this));
    this.game.renderer.showList({
      header: header,
      items: (function() {
        var j, len, results;
        results = [];
        for (j = 0, len = _choices.length; j < len; j++) {
          v = _choices[j];
          results.push(v.key + " - " + v.name);
        }
        return results;
      })()
    });
    return this.keys(null, ['escape'].concat(slice.call(_.keys(mapDisplayed)))).then((function(_this) {
      return function(key) {
        var choice;
        _this.game.renderer.showList(null);
        if (key === 'escape') {
          return null;
        }
        choice = mapDisplayed[key];
        return {
          key: choice.key,
          value: choices[choice.index],
          index: choice.index
        };
      };
    })(this));
  };

  TtyPrompts.prototype.multichoiceList = function(header, choices, opts) {
    var _choices, done, i, mapDisplayed, updateList, v;
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
    }).call(this);
    mapDisplayed = _.zipObject((function() {
      var j, len, results;
      results = [];
      for (j = 0, len = _choices.length; j < len; j++) {
        v = _choices[j];
        results.push([this.pressedKey(v.key), v]);
      }
      return results;
    }).call(this));
    updateList = (function(_this) {
      return function() {
        return _this.game.renderer.showList({
          header: header,
          items: (function() {
            var j, len, results;
            results = [];
            for (j = 0, len = _choices.length; j < len; j++) {
              v = _choices[j];
              results.push(v.key + " " + (v.checked ? '+' : '-') + " " + v.name);
            }
            return results;
          })()
        });
      };
    })(this);
    updateList();
    done = false;
    return whilst((function() {
      return !done;
    }), (function(_this) {
      return function() {
        return _this.keys(null, ['escape', 'enter'].concat(slice.call(_.keys(mapDisplayed)))).then(function(key) {
          var choice;
          switch (key) {
            case 'enter':
              done = true;
              break;
            case 'escape':
              done = 'cancel';
              break;
            default:
              choice = mapDisplayed[key];
              choice.checked = !choice.checked;
          }
          return updateList();
        });
      };
    })(this)).then((function(_this) {
      return function() {
        var choice, j, len, results;
        _this.game.renderer.showList(null);
        if (done === 'cancel') {
          return null;
        }
        results = [];
        for (j = 0, len = _choices.length; j < len; j++) {
          choice = _choices[j];
          if (choice.checked) {
            results.push({
              key: choice.key,
              value: choices[choice.index],
              index: choice.index
            });
          }
        }
        return results;
      };
    })(this));
  };

  TtyPrompts.prototype.position = function(message, opts) {
    var bounds, camera, cancelled, done, pos, ref1, ref2, ref3, ref4;
    if (opts == null) {
      opts = {};
    }
    this.game.renderer.setPromptMessage(message);
    camera = this.game.renderer.camera;
    bounds = {
      x: 0 + camera.x,
      y: 1 + camera.y,
      w: camera.viewport.w,
      h: camera.viewport.h
    };
    pos = {
      x: (ref1 = (ref2 = opts["default"]) != null ? ref2.x : void 0) != null ? ref1 : camera.x,
      y: (ref3 = (ref4 = opts["default"]) != null ? ref4.y : void 0) != null ? ref3 : camera.y
    };
    cancelled = false;
    done = false;
    return whilst((function() {
      return !done;
    }), (function(_this) {
      return function() {
        if (typeof opts.progress === "function") {
          opts.progress(pos);
        }
        _this.game.renderer.setCursorPos(pos.y - camera.y + 1, pos.x - camera.x + 0);
        return _this.generic(null, ['key.escape', 'key.enter', 'action.**'], function() {
          var action, event, params;
          event = arguments[0], action = arguments[1], params = 3 <= arguments.length ? slice.call(arguments, 2) : [];
          return (event === 'key.escape' || event === 'key.enter') || action === 'direction';
        }).then(function(arg) {
          var action, dir, event;
          event = arg[0], action = arg[1], dir = arg[2];
          switch (event) {
            case 'key.escape':
              done = true;
              return cancelled = true;
            case 'key.enter':
              return done = true;
            default:
              pos = vectorMath.add(pos, direction.parse(dir));
              pos.x = snapToRange(camera.x, pos.x, camera.x + camera.viewport.w - 1);
              return pos.y = snapToRange(camera.y, pos.y, camera.y + camera.viewport.h - 1);
          }
        });
      };
    })(this)).then(function() {
      if (!cancelled) {
        return pos;
      } else {
        return null;
      }
    });
  };

  return TtyPrompts;

})(Prompts);
