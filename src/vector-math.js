import _ from 'lodash';

export function add(v0, v1) {
	return {
		x: v0.x + v1.x,
		y: v0.y + v1.y
	};
}

export function subtract(v0, v1) {
	return {
		x: v0.x - v1.x,
		y: v0.y - v1.y
	};
}

export const sub = subtract;

export function multiply(v0, v1) {
	if(_.isNumber(v1))
		v1 = { x: v1, y: v1 };

	return {
		x: v0.x * v1.x,
		y: v0.y * v1.y
	};
}

export const mult = multiply;

export function divide(v0, v1) {
	if(_.isNumber(v1))
		v1 = { x: v1, y: v1 };

	return {
		x: v0.x / v1.x,
		y: v0.y / v1.y
	};
}

export const div = divide;
