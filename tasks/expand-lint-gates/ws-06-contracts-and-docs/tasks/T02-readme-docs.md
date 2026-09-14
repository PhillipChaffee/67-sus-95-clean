# T02 (ws-06) root README + docs landing page

Depends on: ws-01..ws-05 · Touched: `README.md`,
`docs/index.html`, `scripts/verify-sync.sh` if the layout example changes

## Steps

1. Root README: the "Languages" table gains the new gate information
   (hygiene and supply-chain columns or rows, matching the existing shape:
   folder | lint | types | docs | coverage | formatter: extend deliberately,
   do not mangle).
2. Root README: the "house rules every folder shares" section gains the new
   guarantees (hygiene gates, supply-chain gates) stated as house-wide rules
   with the same voice as rules 1–6.
3. Root README: the layout table row for scripts/ if make sure that-sync changed.
4. docs/index.html: mirror the README table (the page and the README must
   never disagree).
5. Mechanical check (this is the epic's UX fixture): grep docs/index.html
   and README.md for every new gate name from the audit list: each must
   appear. Save the rendered index.html under the epic's notes/ as the
   fixture.
6. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] The language table shows every new gate per language.
- [ ] docs/index.html matches the README tables.
- [ ] House rules mention the new gate families.

Negative:

- [ ] No table row claims a gate a folder does not enforce (cross-check each
      folder README).
- [ ] The refused families do not appear as offered gates.
- [ ] make sure that-sync passes.
