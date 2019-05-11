declare module "named-js-regexp" {
	interface NamedRegExpExecArray extends RegExpExecArray {
		groups(all?: boolean): object;
		group(name: string, all?: boolean): string;
	}

	interface NamedRegExp extends RegExp {
		exec(expression: string): NamedRegExpExecArray | null;
		execGroups(expression: string, all?: boolean): object;
		groupsIndices(): object;
		replace(text: string, replacement: string | ((this: NamedRegExpExecArray | null, match?, ...params) => string));
	}

	let createNamedRegexp: (pattern: string | RegExp | boolean, flags?: string) => NamedRegExp;
	export = createNamedRegexp;
}
