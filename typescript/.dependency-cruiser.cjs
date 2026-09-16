// The dependency-graph contract for the template layout, checked by
// dependency-cruiser validate (depcruise). dependency-cruiser 18.3.1 is
// pinned in package.json. Every rule carries its reason; a rule whose
// reason dies gets deleted on the next review.

module.exports = {
	forbidden: [
		{
			name: "no-circular",
			severity: "error",
			comment:
				"a module cycle compiles but cannot be reasoned about top-down; break the cycle by extracting the shared shape (the depcruiser equivalent of the python/rust layer contracts)",
			from: {},
			to: {
				circular: true,
			},
		},
		{
			name: "no-orphans",
			severity: "error",
			comment:
				"a module nothing imports and that is not an entry point is dead weight the knip dead-file gate and this check both own; dependency-cruiser is the second opinion that also sees dynamic imports",
			from: {
				orphan: true,
				pathNot: ["node_modules", "\\.d\\.ts$"],
			},
			to: {},
		},
		{
			name: "entry-is-leaf",
			severity: "error",
			comment:
				"nothing may import the entry point: src/index.ts is the outbound edge of the package (what other modules import), not a layer below the shipped code",
			from: {
				pathNot: ["node_modules"],
			},
			to: {
				path: "^src/index\\.ts$",
			},
		},
	],
	options: {
		doNotFollow: {
			path: "node_modules",
		},
	},
};