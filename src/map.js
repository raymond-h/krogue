var Promise, TimeManager, _, filter, log, repeat,
  slice = [].slice;

_ = require('lodash');

TimeManager = require('rl-time-manager');

Promise = require('bluebird');

repeat = require('./util').repeat;

log = require('./log');

filter = function(e, filter) {
  switch (false) {
    case !_.isFunction(filter):
      return filter(e);
    case !_.isString(filter):
      return e.type === filter;
    case !_.isObject(filter):
      return _.where(e, filter);
    default:
      return true;
  }
};

exports.Map = (function() {
  function Map(w, h, data1) {
    this.w = w;
    this.h = h;
    this.data = data1 != null ? data1 : [];
    this.entities = [];
    this.positions = {};
    this.timeManager = new TimeManager(Promise.resolve.bind(Promise));
  }

  Map.prototype.addEntity = function() {
    var e, entities, j, len, ref, ref1;
    entities = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    for (j = 0, len = entities.length; j < len; j++) {
      e = entities[j];
      e.map = this;
    }
    (ref = this.entities).push.apply(ref, entities);
    (ref1 = this.timeManager).add.apply(ref1, entities);
    return this;
  };

  Map.prototype.removeEntity = function() {
    var e, entities, j, len, ref;
    entities = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    for (j = 0, len = entities.length; j < len; j++) {
      e = entities[j];
      e.map = null;
    }
    _.pull.apply(_, [this.entities].concat(slice.call(entities)));
    (ref = this.timeManager).remove.apply(ref, entities);
    return this;
  };

  Map.prototype.entitiesAt = function(x, y, f) {
    var _filter, e, j, len, ref, results;
    _filter = function(e) {
      return (filter(e, f)) && (e.x === x) && (e.y === y);
    };
    ref = this.entities;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      e = ref[j];
      if (_filter(e)) {
        results.push(e);
      }
    }
    return results;
  };

  Map.prototype.listEntities = function(f) {
    var e, j, len, ref, results;
    ref = this.entities;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      e = ref[j];
      if (filter(e, f)) {
        results.push(e);
      }
    }
    return results;
  };

  Map.prototype.collidable = function(x, y) {
    var ref, ref1, ref2, ref3;
    if (_.isObject(x)) {
      ref = x, x = ref.x, y = ref.y;
    }
    return (ref1 = (ref2 = this.data[y]) != null ? (ref3 = ref2[x]) != null ? ref3.collidable : void 0 : void 0) != null ? ref1 : false;
  };

  Map.prototype.hasBlockingEntities = function(x, y) {
    var e, j, len, ref;
    ref = this.entities;
    for (j = 0, len = ref.length; j < len; j++) {
      e = ref[j];
      if (e.x === x && e.y === y) {
        if (e.blocking) {
          return true;
        }
      }
    }
    return false;
  };

  Map.prototype.seeThrough = function(x, y) {
    var ref, ref1, ref2, ref3;
    if (_.isObject(x)) {
      ref = x, x = ref.x, y = ref.y;
    }
    return (ref1 = (ref2 = this.data[y]) != null ? (ref3 = ref2[x]) != null ? ref3.seeThrough : void 0 : void 0) != null ? ref1 : true;
  };

  Map.compressData = function(data) {
    var currentCount, currentTile, findInTable, j, k, len, len1, row, tile, tileData, tileTable, tti, x, y;
    tileTable = [];
    tileData = [];
    findInTable = (function(_this) {
      return function(tile) {
        return _.findIndex(tileTable, (function(t) {
          return _.isEqual(t, tile);
        }), _this);
      };
    })(this);
    currentTile = -1;
    currentCount = 0;
    for (y = j = 0, len = data.length; j < len; y = ++j) {
      row = data[y];
      for (x = k = 0, len1 = row.length; k < len1; x = ++k) {
        tile = row[x];
        tti = findInTable(tile);
        if (tti < 0) {
          tti = tileTable.length;
          tileTable.push(tile);
        }
        if (tti !== currentTile) {
          if (currentTile >= 0) {
            tileData.push([currentTile, currentCount]);
          }
          currentTile = tti;
          currentCount = 1;
        } else {
          currentCount++;
        }
      }
    }
    tileData.push([currentTile, currentCount]);
    return {
      tileTable: tileTable,
      tileData: tileData,
      rleWidth: data[0].length
    };
  };

  Map.decompressData = function(arg) {
    var count, data, i, j, len, results, rleWidth, row, tileData, tileTable, tti, x, y;
    tileTable = arg.tileTable, tileData = arg.tileData, rleWidth = arg.rleWidth;
    if (rleWidth != null) {
      data = _.flatten((function() {
        var j, len, ref, results;
        results = [];
        for (j = 0, len = tileData.length; j < len; j++) {
          ref = tileData[j], tti = ref[0], count = ref[1];
          results.push(repeat(count, tileTable[tti]));
        }
        return results;
      })());
      tileData = (function() {
        var j, ref, ref1, results;
        results = [];
        for (i = j = 0, ref = data.length, ref1 = rleWidth; ref1 > 0 ? j < ref : j > ref; i = j += ref1) {
          results.push(data.slice(i, i + rleWidth));
        }
        return results;
      })();
      return tileData;
    } else {
      results = [];
      for (y = j = 0, len = tileData.length; j < len; y = ++j) {
        row = tileData[y];
        results.push((function() {
          var k, len1, results1;
          results1 = [];
          for (x = k = 0, len1 = row.length; k < len1; x = ++k) {
            tti = row[x];
            results1.push(tileTable[tti]);
          }
          return results1;
        })());
      }
      return results;
    }
  };

  return Map;

})();
