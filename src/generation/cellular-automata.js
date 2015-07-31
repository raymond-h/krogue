var generation, initialMap, neighbourCount, printMap;

printMap = function(map) {
  var k, len, results, row;
  results = [];
  for (k = 0, len = map.length; k < len; k++) {
    row = map[k];
    results.push(console.error(row.join('')));
  }
  return results;
};

neighbourCount = function(data, x, y) {
  var count, i, j, k, l, ref, ref1, ref2, ref3, ref4, ref5;
  count = 0;
  for (i = k = ref = x - 1, ref1 = x + 1; ref <= ref1 ? k <= ref1 : k >= ref1; i = ref <= ref1 ? ++k : --k) {
    for (j = l = ref2 = y - 1, ref3 = y + 1; ref2 <= ref3 ? l <= ref3 : l >= ref3; j = ref2 <= ref3 ? ++l : --l) {
      if (((ref4 = (ref5 = data[j]) != null ? ref5[i] : void 0) != null ? ref4 : 1) === 1) {
        count++;
      }
    }
  }
  return count;
};

initialMap = function(width, height, wallProb, randomFn) {
  var k, ref, results, x, y;
  if (randomFn == null) {
    randomFn = Math.random;
  }
  results = [];
  for (y = k = 0, ref = height; 0 <= ref ? k < ref : k > ref; y = 0 <= ref ? ++k : --k) {
    results.push((function() {
      var l, ref1, results1;
      results1 = [];
      for (x = l = 0, ref1 = width; 0 <= ref1 ? l < ref1 : l > ref1; x = 0 <= ref1 ? ++l : --l) {
        if ((x === 0 || x === (width - 1)) || (y === 0 || y === (height - 1))) {
          results1.push(1);
        } else if (randomFn() <= wallProb) {
          results1.push(1);
        } else {
          results1.push(0);
        }
      }
      return results1;
    })());
  }
  return results;
};

generation = function(width, height, data, ruleFn) {
  var isWall, k, ref, results, x, y;
  results = [];
  for (y = k = 0, ref = height; 0 <= ref ? k < ref : k > ref; y = 0 <= ref ? ++k : --k) {
    results.push((function() {
      var l, ref1, results1;
      results1 = [];
      for (x = l = 0, ref1 = width; 0 <= ref1 ? l < ref1 : l > ref1; x = 0 <= ref1 ? ++l : --l) {
        isWall = ruleFn(x, y, neighbourCount(data, x, y));
        if (isWall) {
          results1.push(1);
        } else {
          results1.push(0);
        }
      }
      return results1;
    })());
  }
  return results;
};

exports.createMap = function(arg) {
  var data, height, initProbability, k, len, randomFn, ruleFn, rules, width;
  width = arg.width, height = arg.height, initProbability = arg.initProbability, rules = arg.rules, randomFn = arg.randomFn;
  data = initialMap(width, height, initProbability, randomFn);
  for (k = 0, len = rules.length; k < len; k++) {
    ruleFn = rules[k];
    data = generation(width, height, data, ruleFn);
  }
  return data;
};
