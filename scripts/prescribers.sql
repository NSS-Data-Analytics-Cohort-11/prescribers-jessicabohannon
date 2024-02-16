/*1.*/
--    a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi AS prescriber,
	SUM(total_claim_count_ge65) AS total_claims
FROM prescription
GROUP BY npi
HAVING SUM(total_claim_count_ge65) IS NOT NULL
ORDER BY total_claims DESC;

--Answer: 1881634483
    
--    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT dr.nppes_provider_first_name AS prescriber_first_name,
	dr.nppes_provider_last_org_name AS prescriber_last_name,
	dr.specialty_description AS specialty,
	SUM(med.total_claim_count_ge65) AS total_claims
FROM prescriber AS dr
INNER JOIN prescription AS med
USING(npi)
GROUP BY prescriber_first_name, prescriber_last_name, specialty
HAVING SUM(total_claim_count_ge65) IS NOT NULL
ORDER BY total_claims DESC;

--Answer: Bruce Pendley, Family Practice, 70549 claims

/*2.*/ 
--    a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT dr.specialty_description AS specialty,
	SUM(med.total_claim_count_ge65) AS total_claims
FROM prescriber AS dr
INNER JOIN prescription AS med
USING(npi)
GROUP BY specialty
HAVING SUM(total_claim_count_ge65) IS NOT NULL
ORDER BY total_claims DESC;

--Answer: Family Practice

--    b. Which specialty had the most total number of claims for opioids?

SELECT dr.specialty_description AS specialty,
	SUM(med.total_claim_count_ge65) AS total_claims
FROM prescriber AS dr
INNER JOIN prescription AS med
USING(npi)
INNER JOIN drug AS d
USING(drug_name)
WHERE d.opioid_drug_flag = 'Y'
GROUP BY specialty
HAVING SUM(total_claim_count_ge65) IS NOT NULL
ORDER BY total_claims DESC;

--Answer: Nurse Practitioner

--    c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT dr.specialty_description AS specialty,
	SUM(med.total_claim_count_ge65) AS total_claims
FROM prescriber AS dr
INNER JOIN prescription AS med
USING(npi)
GROUP BY specialty
HAVING SUM(total_claim_count_ge65) IS NULL
	OR SUM(total_claim_count_ge65) = 0
ORDER BY total_claims DESC;

--Yes, three are NULL and 6 are 0, including Counselor and Psychologist

--    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

--Will come back to this later, but use case when similar to the % male/female names question I did recently

/*3.*/ 
--    a. Which drug (generic_name) had the highest total drug cost?

-----Robert said something about summing the total_cost?

SELECT d.generic_name AS drug,
	ROUND(total_drug_cost, 2) AS drug_cost
FROM prescription AS p
INNER JOIN drug AS d
USING(drug_name)
ORDER BY drug_cost DESC
LIMIT 10;

--Answer: PIRFENIDONE costs $2,829,174.30!

--    b. Which drug (generic_name) has the hightest total cost per day? 

SELECT d.generic_name AS drug,
	ROUND(total_drug_cost/total_day_supply, 2) AS drug_cost_per_day
FROM prescription AS p
INNER JOIN drug AS d
USING(drug_name)
ORDER BY drug_cost_per_day DESC
LIMIT 1;

--Answer: IMMUN GLOB G(IGG)/GLY/IGA OV50

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
	SUM(p.total_drug_cost) AS sum_drug_cost
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

SELECT COUNT(*)
FROM cbsa
WHERE cbsaname ILIKE '%, TN';

--Answer: 33

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
USING(drug_name)
WHERE dr.specialty_description = 'Pain Management'
	AND dr.nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber, drug_name;
    
--    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT dr.npi AS prescriber,
	d.drug_name,
	COALESCE(SUM(p.total_claim_count), 0) AS num_claims
FROM prescriber AS dr
CROSS JOIN drug AS d
LEFT JOIN prescription AS p
USING(drug_name)
WHERE dr.specialty_description = 'Pain Management'
	AND dr.nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber, drug_name;