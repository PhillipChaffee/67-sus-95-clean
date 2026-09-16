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
import sonarjs from "eslint-plugin-sonarjs";
import { defineConfig } from "eslint/config";
import tseslint from "typescript-eslint";
import vitest from "@vitest/eslint-plugin";

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
    // Stale suppressions fail the build: an eslint-disable whose rule no
    // longer fires is dead weight that hides the next real finding. This is
    // the escalation from warn (the eslint default for unused directives) to
    // error, so a stale disable directive fails the lint run like any other
    // violation.
    linterOptions: { reportUnusedDisableDirectives: "error" },
  },
  {
    // Sonar's metric gates, explicitly enabled (the plugin's `recommended`
    // bundle pulls in more surface than this slice needs; each rule stands
    // on its own reason). eslint-plugin-sonarjs 4.2.1 ships all three; the
    // plugin pin lives in package.json next to the other pins. Same file
    // scope as the core metric caps: the config files sit outside.
    files: ["**/*.{js,cjs,jsx,ts,cts,mts,tsx}"],
    plugins: { sonarjs },
    rules: {
      // Cognitive complexity, 15: Sonar's own documented issue threshold for
      // the metric (S3776); counting nesting and breaks, it catches the deep
      // shape cyclomatic complexity (complexity above) does not.
      "sonarjs/cognitive-complexity": ["error", 15],
      // A string repeated three or more times is a constant (S1192; the
      // plugin's documented default threshold).
      "sonarjs/no-duplicate-string": ["error", { threshold: 3 }],
      // Commented-out code is dead weight a comment cannot excuse (S125);
      // the plugin ships the rule, so the audit's "no tool" line is closed.
      "sonarjs/no-commented-code": "error",
    },
  },
  {
    // eslint core metric caps: NOT in any typescript-eslint preset, so these
    // are explicit core entries on TS sources (the typescript-eslint parser
    // feeds them). Every threshold is either a documented default or a metric
    // gate shared with the other stacks (McCabe 10, screen-sized functions),
    // and none of them judges whitespace — prettier owns the byte. The
    // eslint config files themselves sit outside this block: their own
    // thresholds are literals by definition, and a metric gate that flags
    // its own config trains people to ignore the gate.
    files: ["**/*.{js,cjs,jsx,ts,cts,mts,tsx}"],
    rules: {
      // Unnamed literals in logic (the go folder's mnd signal), with the
      // allowance list every entry of which carries a reason: 0, 1, and -1
      // are identity values whose meaning is the literal itself; array
      // indexes and field initializers name their own values by position.
      "no-magic-numbers": [
        "error",
        {
          ignore: [0, 1, -1],
          ignoreArrayIndexes: true,
          ignoreDefaultValues: true,
          ignoreClassFieldInitialValues: true,
        },
      ],
      // Cyclomatic complexity, max 10: the McCabe reference point (same as
      // the go folder's cyclop max and Sonar's default). Remedy: extract a
      // function.
      complexity: ["error", 10],
      // A file longer than a screen or two is two modules wearing a trench
      // coat. skipComments/skipBlankLines so prose and formatting do not
      // count. Overlaps max-lines-per-function: the file cap bounds the sum,
      // the per-function cap bounds each part.
      "max-lines": [
        "error",
        { max: 300, skipBlankLines: true, skipComments: true },
      ],
      // 40 statements per function: parity with the go folder's funlen
      // statements cap; the fix is mechanical (extract a function).
      "max-statements": ["error", { max: 40 }],
      // 60 lines per function (comments and blank lines excluded): the
      // readable-screen rule, paired with max-statements which bounds
      // density rather than length.
      "max-lines-per-function": [
        "error",
        { max: 60, skipBlankLines: true, skipComments: true },
      ],
      // Nesting depth 4: deeper than that, extraction stops being optional.
      "max-depth": ["error", 4],
      // 3 positional parameters (the eslint documented default): a function
      // with more is an object-taking function; 4th and 5th parameters hide
      // a context object that should be named.
      "max-params": ["error", { max: 3 }],
    },
  },
  {
    // Test files get the tests bar: literals and fixtures are the point of a
    // test, and asserting a boundary value is not a magic number to name.
    // Mirrors the python folder's PLR2004 test carve-out.
    files: ["**/*.{test,spec}.{ts,tsx,cts,mts}"],
    rules: {
      "no-magic-numbers": "off",
    },
  },
  {
    // Vitest's test-style gates, scoped to test files (the plugin's rules
    // only make sense there per its docs, so nothing leaks into shipped
    // code). @vitest/eslint-plugin 1.6.27 is pinned in package.json and
    // reads the project's installed vitest version, so the rules track the
    // vitest pin rather than the plugin's own assumption. A focused slice,
    // each rule its reason: expect-expect makes an assertion-less test a
    // build failure (the assertion-less-test signal the audit targeted);
    // max-nested-describe at 3 keeps describe nesting readable; and
    // no-conditional-expect keeps assertions out of conditionals, where the
    // runner never reaches them.
    files: ["**/*.{test,spec}.{ts,tsx,cts,mts}"],
    plugins: { vitest },
    rules: {
      "vitest/expect-expect": "error",
      "vitest/max-nested-describe": ["error", { max: 3 }],
      "vitest/no-conditional-expect": "error",
    },
  },
);
