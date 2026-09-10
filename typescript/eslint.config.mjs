// @ts-check
// The lint surface: eslint core recommended, typescript-eslint's strict
// type-checked preset, a hand-picked strict slice of eslint-plugin-jsdoc, and
// eslint core's comment rules. Every enablement carries its reason; a rule
// without one gets deleted on the next review.
//
// Deliberately absent, with the reason (house rule: an absence needs its why
// in the config or the README too):
// - `spaced-comment`: deprecated in eslint core since 8.53 (moved to
//   @stylistic); comment whitespace is prettier's job in this stack, and a
//   second formatter-vs-check lattice is more drift surface than value.
// - typescript-eslint's `stylistic` preset: opinion-heavy consistency rules
//   that prettier already normalizes; adding it would make two tools argue
//   about the same byte.
import js from "@eslint/js";
import jsdoc from "eslint-plugin-jsdoc";
import { defineConfig } from "eslint/config";
import tseslint from "typescript-eslint";

export default defineConfig(
  // Build output and coverage reports hold generated code; no lint, no coverage
  // (the coverage gate in vitest.config.ts owns its own include).
  { ignores: ["node_modules/", "dist/", "coverage/"] },
  {
    files: ["**/*.{js,cjs,mjs,jsx,ts,cts,mts,tsx}"],
    extends: [js.configs.recommended], // The @eslint/js baseline for every file format this repo carries, including the config files themselves
  },
  {
    files: ["**/*.{ts,tsx,cts,mts}"],
    extends: [tseslint.configs.strictTypeChecked], // The strict preset WITH type information; the `.js` congeners stay core-recommended so the tool configs here are not out-of-project files for typed lint
    languageOptions: {
      parserOptions: {
        projectService: true, // Typed linting against the tsconfig in this repo (verified shape, typescript-eslint "getting started/typed linting")
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    // The doc-comment machine. Scoped to TS sources: the `.mjs`/`.cjs` files in
    // this repo are tool configs, not shipped API, and the rust baseline scoped
    // `missing_docs` the same way ("no undocumented public item").
    files: ["**/*.{ts,tsx,cts,mts}"],
    plugins: { jsdoc },
    rules: {
      // Every exported function (declaration, expression, arrow) and every
      // declared-but-typed-over function needs a doc comment; the boundary is
      // "shipped API", the same one rust's `missing_docs` uses.
      "jsdoc/require-jsdoc": [
        "error",
        {
          contexts: [
            {
              context:
                "ExportNamedDeclaration > VariableDeclaration > VariableDeclarator > ArrowFunctionExpression",
            }, // Default contexts miss arrows, and those ship
            {
              context:
                "ExportNamedDeclaration > VariableDeclaration > VariableDeclarator > FunctionExpression",
            },
          ],
        },
      ],
      // A doc that restates the bare signature is the bug this repo's rules
      // exist to catch: the block description is required, so "@param x the x"
      // alone will not pass.
      "jsdoc/require-description": "error",
      "jsdoc/require-param": "error", // Each parameter documented (fired even without a block otherwise)
      "jsdoc/require-returns": "error", // A returning function documents what it returns
      "jsdoc/check-param-names": "error", // @param names must match the signature, drift die
      "jsdoc/check-tag-names": "error", // Tags are from the known vocabulary; typos like @retruns do not pass silently
      "jsdoc/require-hyphen-before-param-description": "error", // `@param name - description` punctuation is fixed, because diffs across param lines should not restyle themselves
    },
  },
  {
    // eslint core comment rules for every file they can reach.
    files: ["**/*.{js,cjs,mjs,jsx,ts,cts,mts,tsx}"],
    rules: {
      // Comments start capitalized; inline and consecutive-comment exemptions
      // keep code-tail comments and stacked comment lines usable, and
      // directives (eslint-disable, etc.) plus URL-lead comments are always
      // exempt inside the rule itself (verbatim: the rule's documented
      // always-ignored vocabulary). This is prose hygiene with teeth, not a
      // style war: the fixer handles most of it.
      "capitalized-comments": [
        "error",
        "always",
        { ignoreInlineComments: true, ignoreConsecutiveComments: true },
      ],
      // The todo tripwire: a comment saying work remains FAILS the build. That
      // is the product: tickets live in the tracker, not in the code. Never
      // downgrade this to get a build green.
      "no-warning-comments": ["error", { terms: ["todo", "fixme", "xxx"] }],
    },
  },
);
