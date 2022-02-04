-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
select pscribe.npi, sum(total_claim_count) total_claims
from prescriber pscribe
         inner join prescription p on pscribe.npi = p.npi
group by pscribe.npi
order by total_claims desc;
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

select pscribe.nppes_provider_first_name    prescriber_first_name,
       pscribe.nppes_provider_last_org_name prescriber_last_org_name,
       pscribe.specialty_description        prescriber_specialty_description,
       pscribe.npi                          prescriber_npi,
       sum(total_claim_count)               total_claims
from prescriber pscribe
         inner join prescription p on pscribe.npi = p.npi
group by pscribe.npi, pscribe.nppes_provider_first_name, pscribe.nppes_provider_last_org_name,
         pscribe.specialty_description
order by total_claims desc;

--
-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?
--
select pscribe.specialty_description, sum(total_claim_count) total_claims
from prescriber pscribe
         inner join prescription p on pscribe.npi = p.npi
group by pscribe.specialty_description
order by total_claims desc;

--     b. Which specialty had the most total number of claims for opioids?
--
select distinct pscribe.specialty_description, sum(total_claim_count) total_claims
from prescriber pscribe
         inner join prescription p on pscribe.npi = p.npi
         inner join drug d on p.drug_name = d.drug_name
where d.opioid_drug_flag = 'Y'
group by pscribe.specialty_description
order by total_claims desc;
--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
select distinct prescriber.specialty_description
from prescriber
         full join prescription p on prescriber.npi = p.npi
where drug_name is null
order by prescriber.specialty_description;

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
--

-- 3. a. Which drug (generic_name) had the highest total drug cost?
--
select drug.generic_name, sum(p.total_drug_cost) as drug_cost
from drug
         inner join prescription p on drug.drug_name = p.drug_name
group by generic_name
order by drug_cost desc

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
--

select d.generic_name, round(sum(total_drug_cost) / sum(total_day_supply), 2)::money as total_cost_per_day
from prescription
         inner join drug d on prescription.drug_name = d.drug_name
group by d.generic_name
order by total_cost_per_day desc

-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
--
select drug_name,
       case
           when opioid_drug_flag = 'Y' then 'opioid'
           when antibiotic_drug_flag = 'Y' then 'antibiotic'
           else 'neither'
           end as drug_type
from drug
order by drug_name
--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
--
select sum(total_drug_cost)::money total_cost,
       case
           when opioid_drug_flag = 'Y' then 'opioid'
           when antibiotic_drug_flag = 'Y' then 'antibiotic'
           else 'neither'
           end as                  drug_type
from drug
         inner join prescription p on drug.drug_name = p.drug_name
where antibiotic_drug_flag = 'Y'
   or opioid_drug_flag = 'Y'
group by drug_type
order by total_cost desc

-- 5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
--
select count(distinct cbsa.cbsa) tn_cbsas
from cbsa
         inner join fips_county fc on cbsa.fipscounty = fc.fipscounty
where fc.state = 'TN';

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
--

select *
from (select cbsa.cbsa, sum(population) total_population
      from cbsa
               inner join population p on cbsa.fipscounty = p.fipscounty
      group by cbsa.cbsa
      order by total_population desc
      limit 1) sq1
union
select *
from (select cbsa.cbsa, sum(population) total_population
      from cbsa
               inner join population p on cbsa.fipscounty = p.fipscounty
      group by cbsa.cbsa
      order by total_population asc
      limit 1) sq1

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
select county, population
from fips_county
         inner join population p on fips_county.fipscounty = p.fipscounty
         full join cbsa c on fips_county.fipscounty = c.fipscounty
where cbsa is null
order by population desc

--
-- 6.
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
select * from (select drug_name, sum(total_claim_count) total_claims
from prescription
group by drug_name) subquery
where subquery.total_claims >= 3000
order by subquery.total_claims desc

--
--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
--

select * from (
    select prescription.drug_name,
    sum(total_claim_count) total_claims,
    case
        when opioid_drug_flag = 'Y' then 'opioid'
        when antibiotic_drug_flag = 'Y' then 'antibiotic'
        else 'none'
        end as drug_type
from prescription
inner join drug d on prescription.drug_name = d.drug_name
group by prescription.drug_name, opioid_drug_flag, antibiotic_drug_flag) subquery
where subquery.total_claims >= 3000
order by subquery.total_claims desc


--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
--
-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.
--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will likely only need to use the prescriber and drug tables.
--
--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
--
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.