-- Example joins for the medical codebook data pack.
--
-- These show how the tables in CASE_STUDY_DATA_PACK.MEDICAL_CODEBOOK fit together.
-- They are starting points, not answers. The drugs and diagnosis used here
-- (infliximab, type 2 diabetes, TNF blockers) are only there to keep the
-- results small.
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


-- ---------------------------------------------------------------------------
-- "Which drugs treat disease X?"
--
-- No table in the data pack links a drug to a disease. This query shows one
-- way to get close, using rheumatoid arthritis and the FDA drug classes. It
-- is not a complete answer. Working out how to find and check candidate
-- drugs is the heart of the exercise.
-- ---------------------------------------------------------------------------

-- 5. From the FDA directory: drugs in a pharmacologic class used for the
--    disease, with the HCPCS code each package bills under, if it has one.
--    TNF blockers are one class used for rheumatoid arthritis. You have to
--    know the class first, and a class is not a disease: these drugs are
--    approved for other conditions too, and other classes treat it as well.
--    Drugs the patient takes at home have no HCPCS code here.
SELECT DISTINCT
    UPPER(product.nonproprietary_name) AS drug,
    UPPER(product.proprietary_name)    AS brand,
    crosswalk.hcpcs_code
FROM ndc_product_pharm_class AS pharm_class
JOIN ndc_product AS product
    ON product.product_id = pharm_class.product_id
JOIN ndc_package AS package
    ON package.product_id = product.product_id
LEFT JOIN ndc_hcpcs_crosswalk AS crosswalk
    ON  crosswalk.ndc_11 = package.ndc_11
    AND crosswalk.release = '2026-10'
    AND crosswalk.crosswalk_type = 'ASP'
WHERE pharm_class.pharm_class = 'Tumor Necrosis Factor Blocker'
  AND pharm_class.class_type = 'EPC'
ORDER BY drug, brand;
