# Note: refused metric families (decided, do not re-open)

These two families were reviewed and refused. They are not gaps to fill.

## 1. Coupling and cohesion dashboards (fan-in/fan-out, LCOM, instability)

Why refused:

- Failing them has no mechanical fix. "LCOM is high" prescribes no concrete
  step, unlike cyclomatic complexity, whose fix is "extract a function".
- LCOM has several inconsistent formulas (Chidamber–Kemerer original,
  Henderson-Sellers LCOM*). Implementations disagree on the same code, so
  there is nothing stable to pin.
- Cohesion is a qualitative rubric, not one number (Wikipedia: Cohesion,
  computer science). Turning it into a gate means inventing a threshold.
- No maintained mainstream linter in our four stacks implements them. The
  tools that exist are dormant or dashboard-only.

## 2. Halstead / Maintainability Index / NPath

Why refused ("vanity metrics"):

- They mostly re-measure size. Research on cyclomatic complexity already
  showed it correlates with lines of code and adds no predictive power beyond
  size (Hatton's critique). The Maintainability Index literally contains
  Halstead volume and line counts in its formula, so it is a weighted blend of
  size and the complexity gate we already enforce.
- Halstead's extra outputs are pseudo-precision: "time to program = E/18
  seconds" and "delivered bugs = E^(2/3)/3000" predict nothing actionable.
- MI thresholds (green 20–100, red 0–9) are Visual Studio tooling convention,
  not a standard.
- NPath counts total paths, which multiply with every decision. The numbers
  explode and thresholds lose meaning.
- No mainstream linter in our stacks implements any of them as a build gate.

## The bar to reopen

The refusal is evidence-based, not permanent. If a mainstream linter ships a
stable rule with consistent semantics and a defensible threshold, re-evaluate
it through the normal gate bar (precise definition,
maintained tool, binary gate, proven failure, stated remedy).

Cyclomatic complexity shows the difference: it is a metric too, and it kept
its place because it has all five.
