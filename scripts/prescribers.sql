/*1.*/
--    a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi AS prescriber,
	ROUND(SUM(total_claim_count), 0) AS total_claims
FROM prescription
GROUP BY npi
HAVING SUM(total_claim_count) IS NOT NULL
ORDER BY total_claims DESC
LIMIT 1;

--Answer: Prescriber 1881634483 had 99,707 claims
    
--    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT dr.nppes_provider_first_name AS prescriber_first_name,
	dr.nppes_provider_last_org_name AS prescriber_last_name,
	dr.specialty_description AS specialty,
	ROUND(SUM(med.total_claim_count), 0) AS total_claims
FROM prescriber AS dr
INNER JOIN prescription AS med
USING(npi)
GROUP BY prescriber_first_name, prescriber_last_name, specialty
HAVING SUM(total_claim_count) IS NOT NULL
ORDER BY total_claims DESC
LIMIT 1;

--Answer: Bruce Pendley, Family Practice, 99,707 claims

/*2.*/ 
--    a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT dr.specialty_description AS specialty,
	TO_CHAR(SUM(med.total_claim_count), '999,999,999') AS total_claims
FROM prescriber AS dr
INNER JOIN prescription AS med
USING(npi)
GROUP BY specialty
HAVING SUM(total_claim_count) IS NOT NULL
ORDER BY total_claims DESC
LIMIT 1;

--Answer: Family Practice

--    b. Which specialty had the most total number of claims for opioids?

SELECT dr.specialty_description AS specialty,
	TO_CHAR(SUM(med.total_claim_count), '999,999') AS total_claims
FROM prescriber AS dr
INNER JOIN prescription AS med
USING(npi)
INNER JOIN drug AS d
USING(drug_name)
WHERE d.opioid_drug_flag = 'Y'
GROUP BY specialty
HAVING SUM(total_claim_count) IS NOT NULL
ORDER BY total_claims DESC;

--Answer: Nurse Practitioner

--    c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT dr.specialty_description AS specialty,
	SUM(med.total_claim_count) AS total_claims
FROM prescriber AS dr
LEFT JOIN prescription AS med
USING(npi)
GROUP BY specialty
HAVING SUM(total_claim_count) IS NULL
	OR SUM(total_claim_count) = 0
ORDER BY total_claims DESC;

--Or with an anti-join:

SELECT DISTINCT specialty_description AS specialty
FROM prescriber
WHERE specialty_description NOT IN (
	SELECT specialty_description
	FROM prescriber
	INNER JOIN prescription
	USING(npi)
)
ORDER BY specialty;

--Answer: Yes, 15

--    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

WITH all_drugs AS (
	SELECT dr.specialty_description AS specialty,
		SUM(total_claim_count) AS total_claims
	FROM prescriber AS dr
	INNER JOIN prescription AS p
	USING(npi)
	INNER JOIN drug AS d
	USING(drug_name)
	GROUP BY specialty
),
opioids AS (
	SELECT dr.specialty_description AS specialty,
		SUM(total_claim_count) AS opioid_claims
	FROM prescriber AS dr
	INNER JOIN prescription AS p
	USING(npi)
	INNER JOIN drug AS d
	USING(drug_name)
	WHERE d.opioid_drug_flag = 'Y'
	GROUP BY specialty
)
SELECT specialty,
	COALESCE(ROUND(opioid_claims/total_claims * 100.00, 2), 0) AS perc_opioids
FROM all_drugs
LEFT JOIN opioids
USING(specialty)
ORDER BY perc_opioids DESC;

--Alternatively:

SELECT specialty_description AS specialty,
	SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
		END) as opioid_claims,
	SUM(total_claim_count) AS total_claims,
	ROUND(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
		END) * 100.0 /  SUM(total_claim_count), 2) AS opioid_percentage
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
GROUP BY specialty_description
order by opioid_percentage DESC;

--Answer: Case Manager, Orthopaedic Surgery, Interventional Pain Management, and Anesthesiology are the top 4.

/*3.*/ 
--    a. Which drug (generic_name) had the highest total drug cost?

SELECT d.generic_name AS drug,
	SUM(total_drug_cost) AS drug_cost
FROM prescription AS p
INNER JOIN drug AS d
USING(drug_name)
GROUP BY drug
ORDER BY drug_cost DESC
LIMIT 10;

--Answer: INSULIN GLARGINE,HUM.REC.ANLOG at $104,264,066.35

--    b. Which drug (generic_name) has the hightest total cost per day? 

SELECT d.generic_name AS drug,
	ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2) AS drug_cost_per_day
FROM prescription AS p
INNER JOIN drug AS d
USING(drug_name)
GROUP BY drug
ORDER BY drug_cost_per_day DESC
LIMIT 1;

--Answer: "C1 ESTERASE INHIBITOR" at $3,495.22 per day

/*4.*/ 
--    a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 

SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
FROM drug;

--    b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT CASE WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type,
	SUM(p.total_drug_cost)::MONEY AS sum_drug_cost
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
WHERE CASE WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END <> 'neither'
GROUP BY drug_type
ORDER BY sum_drug_cost DESC;

--More was spent on opioids

/*5.*/ 
--    a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
WHERE state = 'TN';

--Answer: 10

--    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
	
(SELECT c.cbsaname AS city,
        SUM(p.population) AS total_pop
 FROM cbsa AS c
 INNER JOIN population AS p
 USING(fipscounty)
 GROUP BY city
 ORDER BY total_pop DESC
 LIMIT 1)
UNION
(SELECT c.cbsaname AS city,
        SUM(p.population) AS total_pop
 FROM cbsa AS c
 INNER JOIN population AS p
 USING(fipscounty)
 GROUP BY city
 ORDER BY total_pop ASC
 LIMIT 1);

--Answer: Morristown, TN has the smallest population of 116,352; Nashville-Davidson--Murfreesboro--Franklin, TN has the largest population of 1,830,410.

--    c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT f.county,
	p.population
FROM fips_county AS f
INNER JOIN population AS p
USING(fipscounty)
WHERE f.fipscounty NOT IN (SELECT fipscounty FROM cbsa)
ORDER BY p.population DESC
LIMIT 1;

--Answer: Sevier, population 95,523

/*6.*/ 
--    a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name,
	total_claim_count
FROM prescription AS p
WHERE total_claim_count >= 3000;

--    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT p.drug_name,
	p.total_claim_count,
	d.opioid_drug_flag AS is_opioid
FROM prescription AS p
INNER JOIN drug AS d
USING(drug_name)
WHERE total_claim_count >= 3000;

--    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT p.drug_name,
	p.total_claim_count,
	d.opioid_drug_flag AS is_opioid,
	CONCAT(dr.nppes_provider_first_name, ' ', dr.nppes_provider_last_org_name) AS prescriber
FROM prescription AS p
INNER JOIN drug AS d
USING(drug_name)
INNER JOIN prescriber AS dr
USING(npi)
WHERE total_claim_count >= 3000;

/*7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.*/

--    a. First, create a list of all npi/drug_name combinations for pain management specialists in the city of Nashville, where the drug is an opioid.

SELECT dr.npi,
	d.drug_name
FROM prescriber AS dr
CROSS JOIN drug AS d
WHERE dr.specialty_description = 'Pain Management'
	AND dr.nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';

--    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
	
SELECT dr.npi AS prescriber,
	d.drug_name,
	SUM(p.total_claim_count) AS num_claims
FROM prescriber AS dr
CROSS JOIN drug AS d
LEFT JOIN prescription AS p
USING(npi, drug_name)
WHERE dr.specialty_description = 'Pain Management'
	AND dr.nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber, drug_name
ORDER BY prescriber;

--    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0.

SELECT dr.npi AS prescriber,
	d.drug_name,
	COALESCE(SUM(p.total_claim_count), 0) AS num_claims
FROM prescriber AS dr
CROSS JOIN drug AS d
LEFT JOIN prescription AS p
USING(npi, drug_name)
WHERE dr.specialty_description = 'Pain Management'
	AND dr.nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber, drug_name
ORDER BY num_claims DESC;