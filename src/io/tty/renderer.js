var Camera, Effects, LineMan, TtyRenderer, _, blessed, entityClasses, eventBus, graphics, log, parseAttrs, program, wordwrap,
  slice = [].slice;

blessed = require('blessed');

program = blessed.program.global;

wordwrap = require('wordwrap');

_ = require('lodash');

LineMan = require('../line-man');

log = require('../../log');

eventBus = require('../../event-bus');

entityClasses = require('../../entities');

Camera = require('../../camera');

graphics = require('../graphics-ascii');

Effects = require('./effects');

parseAttrs = function(graphic) {
  var attrs;
  attrs = [];
  if (graphic.color != null) {
    attrs.push(graphic.color + " fg");
  }
  return attrs;
};

module.exports = TtyRenderer = (function() {
  TtyRenderer.strMore = ' [more]';

  function TtyRenderer(io, game) {
    var blank, i, logWidth;
    this.io = io;
    this.game = game;
    this.invalidated = false;
    blank = {
      symbol: ' '
    };
    this.buffer = (function() {
      var k, ref, results;
      results = [];
      for (i = k = 0, ref = 80 * 25; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
        results.push(blank);
      }
      return results;
    })();
    this.invalidate();
    logWidth = 80 - TtyRenderer.strMore.length;
    this.lineMan = new LineMan(logWidth);
    eventBus.on('turn.player.start', (function(_this) {
      return function() {
        return _this.invalidate();
      };
    })(this)).on('log.add', (function(_this) {
      return function(str) {
        return _this.lineMan.add(str);
      };
    })(this));
    this.lineMan.on('update', (function(_this) {
      return function() {
        return _this.invalidate();
      };
    })(this));
    this.effects = new Effects(this);
    this.camera = new Camera({
      w: 80,
      h: 21
    }, {
      x: 30,
      y: 9
    });
  }

  TtyRenderer.prototype.bufferPut = function(x, y, graphic) {
    if (_.isString(graphic)) {
      graphic = {
        symbol: graphic
      };
    }
    return this.buffer[y * 80 + x] = graphic;
  };

  TtyRenderer.prototype.write = function(x, y, str) {
    var c, i, k, len, results;
    results = [];
    for (i = k = 0, len = str.length; k < len; i = ++k) {
      c = str[i];
      results.push(this.bufferPut(x + i, y, c));
    }
    return results;
  };

  TtyRenderer.prototype.fillArea = function(x, y, w, h, c) {
    var i, j, k, ref, results;
    c = {
      symbol: c
    };
    results = [];
    for (i = k = 0, ref = w; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
      results.push((function() {
        var l, ref1, results1;
        results1 = [];
        for (j = l = 0, ref1 = h; 0 <= ref1 ? l < ref1 : l > ref1; j = 0 <= ref1 ? ++l : --l) {
          results1.push(this.bufferPut(x + i, y + j, c));
        }
        return results1;
      }).call(this));
    }
    return results;
  };

  TtyRenderer.prototype.bufferToString = function() {
    var currentGraphic, g, i, k, lastAttrs, len, out, ref;
    out = '';
    currentGraphic = {};
    lastAttrs = [];
    ref = this.buffer;
    for (i = k = 0, len = ref.length; k < len; i = ++k) {
      g = ref[i];
      if (currentGraphic !== g && !_.isEqual(currentGraphic, g)) {
        currentGraphic = g;
        out += program._attr(lastAttrs, false);
        lastAttrs = parseAttrs(g);
        out += program._attr(lastAttrs, true);
      }
      out += g.symbol;
      if ((i % 80) === 79) {
        out += '\n';
      }
    }
    return out;
  };

  TtyRenderer.prototype.flipBuffer = function() {
    program.move(0, 0);
    return program.write(this.bufferToString());
  };

  TtyRenderer.prototype.hasMoreLogs = function() {
    return this.lineMan.lines.length > 1;
  };

  TtyRenderer.prototype.showMoreLogs = function() {
    this.lineMan.lines.shift();
    return this.invalidate();
  };

  TtyRenderer.prototype.invalidate = function() {
    if (!this.invalidated) {
      this.invalidated = true;
      return process.nextTick((function(_this) {
        return function() {
          _this.invalidated = false;
          return _this.render();
        };
      })(this));
    }
  };

  TtyRenderer.prototype.setPromptMessage = function(promptMessage) {
    if (promptMessage != null) {
      this.lineMan.add('\n' + promptMessage);
      return this.showMoreLogs();
    }
  };

  TtyRenderer.prototype.showList = function(menu1) {
    this.menu = menu1;
    return this.invalidate();
  };

  TtyRenderer.prototype.setCursorPos = function(x, y) {
    return program.cursorPos(x, y);
  };

  TtyRenderer.prototype.render = function() {
    var x, y;
    switch (this.game.state) {
      case 'game':
        this.renderLog(0, 0);
        this.renderMap(0, 1);
        if (this.menu != null) {
          this.renderMenu(this.menu);
        }
        this.renderHealth(0, 22);
        break;
      case 'death':
        this.renderDeath();
        break;
      default:
        null;
    }
    this.flipBuffer();
    if (this.game.player != null) {
      x = this.game.player.lookPos.x - this.camera.x;
      y = this.game.player.lookPos.y - this.camera.y + 1;
      return this.setCursorPos(y, x);
    }
  };

  TtyRenderer.prototype.renderDeath = function() {
    this.fillArea(0, 0, 80, 25, ' ');
    this.write(0, 0, "Well well, " + this.game.player.creature + ", you have died...");
    this.write(4, 1, "See you around...");
    return this.write(4, 2, "(Ctrl-C to exit.)");
  };

  TtyRenderer.prototype.renderLog = function(x, y) {
    var str;
    this.fillArea(x, y, 80, 1, ' ');
    if (this.lineMan.lines.length > 0) {
      str = this.lineMan.lines[0];
      if (this.hasMoreLogs()) {
        str += TtyRenderer.strMore;
      }
      return this.write(x, y, str);
    }
  };

  TtyRenderer.prototype.renderMenu = function(menu) {
    var delimiter, height, i, k, len, ref, ref1, ref2, results, row, rows, str, width, x, y;
    x = (ref = menu.x) != null ? ref : 0;
    y = (ref1 = menu.y) != null ? ref1 : 1;
    width = menu.width;
    if (width == null) {
      width = Math.max.apply(Math, (function() {
        var k, len, ref2, results;
        ref2 = menu.items;
        results = [];
        for (k = 0, len = ref2.length; k < len; k++) {
          i = ref2[k];
          results.push(i.length);
        }
        return results;
      })());
      width = Math.max(menu.header.length, width);
      width += 2;
    }
    delimiter = _.repeat('-', width - 2);
    rows = [delimiter, menu.header, delimiter].concat(slice.call(menu.items), [delimiter]);
    height = (ref2 = menu.height) != null ? ref2 : rows.length;
    results = [];
    for (i = k = 0, len = rows.length; k < len; i = ++k) {
      row = rows[i];
      str = "|" + row + (_.repeat(' ', width - row.length - 2)) + "|";
      results.push(this.write(x, y + i, str));
    }
    return results;
  };

  TtyRenderer.prototype.renderMap = function(x, y) {
    var c, entities, entityLayer, graphicAt, k, l, map, ref, ref1, sx, sy;
    c = this.camera;
    map = this.game.currentMap;
    c.target = this.game.player.lookPos;
    c.bounds(map);
    c.update();
    graphicAt = (function(_this) {
      return function(x, y) {
        if (_this.game.player.creature.canSee({
          x: x,
          y: y
        })) {
          return _this.getGraphic(map.data[y][x]);
        } else {
          return ' ';
        }
      };
    })(this);
    for (sx = k = 0, ref = c.viewport.w; 0 <= ref ? k < ref : k > ref; sx = 0 <= ref ? ++k : --k) {
      for (sy = l = 0, ref1 = c.viewport.h; 0 <= ref1 ? l < ref1 : l > ref1; sy = 0 <= ref1 ? ++l : --l) {
        this.bufferPut(sx + x, sy + y, graphicAt(c.x + sx, c.y + sy));
      }
    }
    entityLayer = {
      'creature': 3,
      'item': 2,
      'stairs': 1
    };
    entities = map.entities.slice(0).sort(function(a, b) {
      return entityLayer[a.type] - entityLayer[b.type];
    });
    this.renderEntities(x, y, entities);
    return this.renderEffects(x, y);
  };

  TtyRenderer.prototype.renderEntities = function(x, y, entities) {
    var c, e, graphic, k, len, ref, ref1, results;
    c = this.camera;
    results = [];
    for (k = 0, len = entities.length; k < len; k++) {
      e = entities[k];
      if (this.game.player.creature.canSee(e)) {
        if (((c.x <= (ref = e.x) && ref < c.x + c.viewport.w)) && ((c.y <= (ref1 = e.y) && ref1 < c.y + c.viewport.h))) {
          graphic = this.getGraphic(e);
          results.push(this.bufferPut(e.x - c.x + x, e.y - c.y + y, graphic));
        } else {
          results.push(void 0);
        }
      }
    }
    return results;
  };

  TtyRenderer.prototype.renderHealth = function(x, y) {
    var health;
    this.fillArea(x, y, 40, 2, ' ');
    health = this.game.player.creature.health;
    this.renderRatio(x, y, health, ' health');
    return this.renderBar(x, y + 1, 40, health);
  };

  TtyRenderer.prototype.renderRatio = function(x, y, arg, suffix) {
    var current, max, min, str;
    min = arg.min, current = arg.current, max = arg.max;
    if (suffix == null) {
      suffix = '';
    }
    if (min == null) {
      min = 0;
    }
    str = min === 0 ? current + " / " + max + suffix : min + " <= " + current + " <= " + max + suffix;
    return this.write(x, y, str);
  };

  TtyRenderer.prototype.renderBar = function(x, y, w, arg) {
    var current, currentWidth, fullWidth, max, min, restWidth;
    min = arg.min, current = arg.current, max = arg.max;
    if (min == null) {
      min = 0;
    }
    fullWidth = w - 2;
    currentWidth = Math.floor((current - min) / (max - min) * fullWidth);
    restWidth = fullWidth - currentWidth;
    return this.write(x, y, "[" + (_.repeat('=', currentWidth)) + (_.repeat(' ', restWidth)) + "]");
  };

  TtyRenderer.prototype.renderEffects = function(ox, oy) {
    return this.io.effects.renderEffects(ox, oy);
  };

  TtyRenderer.prototype.getGraphic = function(input) {
    var id;
    id = this.getGraphicId(input);
    return graphics.get(id);
  };

  TtyRenderer.prototype.getGraphicId = function(input) {
    var ref;
    if (_.isString(input)) {
      return input;
    } else if (_.isObject(input)) {
      if (_.isPlainObject(input)) {
        return (ref = input.symbol) != null ? ref : input.type;
      } else if (input instanceof entityClasses.Creature) {
        return this.getGraphicId(input.species);
      } else if (input instanceof entityClasses.MapItem) {
        return this.getGraphicId(input.item);
      } else if (input instanceof entityClasses.Stairs) {
        if (input.down) {
          return 'stairsDown';
        } else {
          return 'stairsUp';
        }
      } else {
        return _.camelCase(input.constructor.name);
      }
    }
  };

  return TtyRenderer;

})();
