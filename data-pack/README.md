# Data pack

**You do not need to load these files.** The same data is already in your Snowflake sandbox as clean tables, in `CASE_STUDY_DATA_PACK.MEDICAL_CODEBOOK`. See the diagram and `example_joins.sql` in the repository root.

These are the main source files those tables were built from, kept here for reference. Reference files are unmodified public releases; claims and CPT data are synthetic. The sandbox tables also include the companion files from the same releases, and every published file is on the `FILES` stage in the sandbox.

| Path | What it is | Source |
|---|---|---|
| `reference/icd10cm/fy2027/` | ICD-10-CM code descriptions, FY2027 (effective 2026-10-01) | CMS, `2027-code-descriptions-tabular-order.zip` |
| `reference/hcpcs/2026-07/`, `reference/hcpcs/2026-10/` | HCPCS Level II alpha-numeric files, July and October 2026 (fixed width; layout in `HCPC2026_recordlayout.txt`) | CMS quarterly update |
| `reference/crosswalk/2026-07/`, `reference/crosswalk/2026-10/` | ASP NDC-HCPCS crosswalk, July and October 2026 (Section 508 CSV, latin-1 encoded, header rows above the column names) | CMS ASP pricing files |
| `reference/ndc/2026-10-19/ndctext.zip` | FDA NDC Directory, product and package files (tab-delimited), snapshot of 2026-10-19 | FDA |
| `synthetic/cpt_synthetic.csv` | Synthetic stand-in for CPT procedure codes (codes `X1001`-`X4004`) | Ambit, synthetic |
| `synthetic/claims_2026.csv` | Synthetic medical and pharmacy claim lines, January to mid-October 2026 | Ambit, synthetic |
| `billing_rules.csv` | Starter billing rules (BR-1 to BR-5), deliberately incomplete | Ambit |

## Things to know

- **The claims are fictional, but treat them as if they were real.** They include PHI-like fields: names, dates of birth, member IDs, and ZIP codes. None of these belong in a codebook, a prompt, a trace, or a log.
- **CPT is licensed by the AMA**, so we use synthetic codes. Do not substitute real CPT content. (A few vaccine CPT codes appear in the CMS crosswalk as published; leave them as they are.)
- **The crosswalk covers Medicare Part B drugs.** It is not a list of every drug or every NDC.
- The HCPCS and crosswalk files come in two quarters so you can show how your system handles a new reference version.

Checksums are in `MANIFEST.sha256`.
