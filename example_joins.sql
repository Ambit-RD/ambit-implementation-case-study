-- Example joins for the medical codebook data pack.
--
-- These show how the tables in CASE_STUDY_DATA_PACK.MEDICAL_CODEBOOK fit together.
-- They are starting points, not answers. The drug and diagnosis used here
-- (infliximab, type 2 diabetes) are only there to keep the results small.
-- The diagram of the tables is in medical_codebook_erd.png.

USE SCHEMA CASE_STUDY_DATA_PACK.MEDICAL_CODEBOOK;


-- 1. Which releases are loaded, and when each one is in effect.
--    Every reference table has a RELEASE column that points here.
SELECT
    reference_set,
    release,
    effective_from,
    effective_to
FROM reference_release
ORDER BY reference_set, release;


-- 2. Drug package -> product -> route.
--    A product has one or more packages, and zero or more routes.
SELECT
    package.ndc_11,
    package.package_description,
    product.proprietary_name,
    product.nonproprietary_name,
    product.dosage_form,
    route.route
FROM ndc_package AS package
JOIN ndc_product AS product
    ON product.product_id = package.product_id
LEFT JOIN ndc_product_route AS route
    ON route.product_id = product.product_id
WHERE product.nonproprietary_name ILIKE 'infliximab%'
ORDER BY package.ndc_11, route.route;


-- 3. HCPCS code -> crosswalk -> drug package.
--    HCPCS and the crosswalk each hold two quarterly releases, so join on
--    the code and the release. The join to NDC_PACKAGE is a LEFT JOIN
--    because not every crosswalk NDC is in the FDA directory.
SELECT
    hcpcs.hcpcs_code,
    hcpcs.short_description,
    crosswalk.ndc_11,
    crosswalk.drug_name,
    crosswalk.billing_units_per_package,
    package.package_description
FROM hcpcs_code AS hcpcs
JOIN ndc_hcpcs_crosswalk AS crosswalk
    ON  crosswalk.hcpcs_code = hcpcs.hcpcs_code
    AND crosswalk.release = hcpcs.release
LEFT JOIN ndc_package AS package
    ON package.ndc_11 = crosswalk.ndc_11
WHERE hcpcs.release = '2026-10'
  AND crosswalk.crosswalk_type = 'ASP'
  AND hcpcs.hcpcs_code = 'J1745'
ORDER BY crosswalk.ndc_11;


-- 4. ICD-10-CM code -> its parent.
--    PARENT_CODE points to the next level up in the same table.
SELECT
    code.code_dotted,
    code.long_description,
    parent.code_dotted      AS parent_code_dotted,
    parent.long_description AS parent_description
FROM icd10cm_code AS code
LEFT JOIN icd10cm_code AS parent
    ON  parent.code = code.parent_code
    AND parent.release = code.release
WHERE code.category_code = 'E11'
  AND code.is_billable
ORDER BY code.code;


-- 5. Medical claim -> lines -> HCPCS description.
--    A claim line has a code but no release, so this pins one release.
--    Which release applies to each service date is your decision.
SELECT
    claim.claim_id,
    claim.service_date,
    line.claim_line,
    line.hcpcs_code,
    hcpcs.short_description,
    line.units
FROM claim
JOIN claim_line AS line
    ON line.claim_id = claim.claim_id
LEFT JOIN hcpcs_code AS hcpcs
    ON  hcpcs.hcpcs_code = line.hcpcs_code
    AND hcpcs.release = '2026-10'
WHERE claim.claim_type = 'MEDICAL'
  AND line.hcpcs_code IS NOT NULL
ORDER BY claim.claim_id, line.claim_line
LIMIT 20;


-- 6. Medical claim -> primary diagnosis -> ICD-10-CM description.
--    Diagnoses are per claim, not per line. Position 1 is the primary one.
SELECT
    claim.claim_id,
    claim.service_date,
    diagnosis.icd10cm_code,
    icd.code_dotted,
    icd.long_description
FROM claim
JOIN claim_diagnosis AS diagnosis
    ON  diagnosis.claim_id = claim.claim_id
    AND diagnosis.position = 1
LEFT JOIN icd10cm_code AS icd
    ON  icd.code = diagnosis.icd10cm_code
    AND icd.release = 'FY2027'
ORDER BY claim.claim_id
LIMIT 20;


-- 7. Pharmacy claim -> lines -> drug package -> product.
--    Pharmacy lines carry an NDC. NDC_11 is the same 11-digit form everywhere.
SELECT
    claim.claim_id,
    claim.service_date,
    line.ndc_11,
    product.proprietary_name,
    product.nonproprietary_name,
    line.quantity,
    line.days_supply
FROM claim
JOIN claim_line AS line
    ON line.claim_id = claim.claim_id
JOIN ndc_package AS package
    ON package.ndc_11 = line.ndc_11
JOIN ndc_product AS product
    ON product.product_id = package.product_id
WHERE claim.claim_type = 'PHARMACY'
ORDER BY claim.claim_id, line.claim_line
LIMIT 20;
