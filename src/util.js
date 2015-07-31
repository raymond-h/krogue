import _ from 'lodash';
import Promise from 'bluebird';

export function bresenhamLine(p0, p1, callback) {
	let result;

	let { x: x0, y: y0 } = p0;
	const { x: x1, y: y1 } = p1;

	const dx = Math.abs(x1 - x0);
	const dy = Math.abs(y1 - y0);
	const sx = x0 < x1 ? 1 : -1;
	const sy = y0 < y1 ? 1 : -1;
	let err = dx - dy;

	if (callback == null) {
		result = [];
		callback = function(x, y) {
			return result.push({ x, y });
		};
	}

	while(true) {
		if((callback(x0, y0)) === false) {
			break;
		}
		if(x0 === x1 && y0 === y1) {
			break;
		}

		const e2 = 2 * err;
		if(e2 > -dx) {
			err -= dy;
			x0 += sx;
		}
		if(e2 < dy) {
			err += dx;
			y0 += sy;
		}
	}

	return result;
}

export function makePromise(val) {
	return Promise.resolve(val);
}

export const p = makePromise;

export function whilst(test, fn) {
	let iteration;
	return (iteration = function() {
		return Promise.resolve(test()).then(function(doLoop) {
			if (doLoop) {
				return Promise.resolve(fn()).then(iteration);
			}
		});
	})();
}

exports.edge = function(r, edge) {
	switch (edge) {
		case 'left':
			return r.x;
		case 'right':
			return r.x + r.w;
		case 'top':
		case 'up':
			return r.y;
		case 'bottom':
		case 'down':
			return r.y + r.h;
	}
};

export function snapToRange(min, curr, max) {
	return Math.max(min, Math.min(curr, max));
}

export function repeat(n, item) {
	const results = [];
	for(let i = 0; i < n; i++) {
		results.push(item);
	}
	return results;
}

export function distanceSq(o0, o1) {
	const [dx, dy] = [o1.x - o0.x, o1.y - o0.y];
	return dx * dx + dy * dy;
}

export function distance(o0, o1) {
	return Math.sqrt(exports.distanceSq(o0, o1));
}
