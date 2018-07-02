-- Create file that sums units matched for ease of seeing projects with units remaining

/**Add in DOB units matched**/

ALTER TABLE capitalplanning.all_possible_projects
ADD COLUMN num_dob_jobs_matched numeric, 
ADD COLUMN dob_u_matched numeric, 
ADD COLUMN num_hpd_matched numeric, 
ADD COLUMN incremental_hpd_u_matched numeric,
ADD COLUMN num_edc_matched numeric, 
ADD COLUMN incremental_edc_u_matched numeric,
ADD COLUMN remaining_dcp_units numeric;

WITH matches AS (
SELECT p.project_id, p.units, count(dob_job_number), sum(u_init) AS u_init, sum(u_prop) AS u_prop, sum(u_net) AS u_net, sum(u_net_complete) AS u_net_complete, sum(u_net_incomplete) AS u_net_incomplete, sum(u_net_complete)+sum(u_net_incomplete) AS u_net_summed
FROM capitalplanning.dcp_dob_dedupe AS p
GROUP BY p.project_id, p.units)

UPDATE capitalplanning.all_possible_projects
SET num_dob_jobs_matched = m.count, dob_u_matched = greatest(m.u_net, m.u_net_summed)
FROM matches AS m WHERE all_possible_projects.project_id = m.project_id

/**Add in HPD units matched**/

WITH matches AS (
SELECT project_id, units, count(CONCAT(hpd_project_id, building_id)), sum(incremental_hpd_units)
FROM capitalplanning.dcp_hpd_dedupe
GROUP BY project_id, units)
  
UPDATE capitalplanning.all_possible_projects
SET num_hpd_matched = m.count, incremental_hpd_u_matched = m.sum
FROM matches AS m WHERE all_possible_projects.project_id = m.project_id

/**Add in EDC units matched**/

WITH matches AS (
SELECT project_id, units, count(edc_id), sum(incremental_edc_units)
FROM capitalplanning.dcp_edc_dedupe
GROUP BY project_id, units)

UPDATE capitalplanning.all_possible_projects
SET num_edc_matched = m.count, incremental_edc_u_matched = m.sum 
FROM matches AS m WHERE all_possible_projects.project_id = m.project_id

/**Calculate units remaining**/

UPDATE capitalplanning.all_possible_projects
SET remaining_dcp_units = (
CASE WHEN dob_u_matched is not null AND incremental_hpd_u_matched is not null AND incremental_edc_u_matched is not null
THEN units - dob_u_matched - incremental_hpd_u_matched - incremental_edc_u_matched
WHEN dob_u_matched is null AND incremental_hpd_u_matched is null AND incremental_edc_u_matched is null
THEN units
WHEN dob_u_matched is null AND incremental_hpd_u_matched is not null AND incremental_edc_u_matched is not null
THEN units - incremental_hpd_u_matched - incremental_edc_u_matched
WHEN dob_u_matched is null AND incremental_hpd_u_matched is null AND incremental_edc_u_matched is not null
THEN units - incremental_edc_u_matched
WHEN dob_u_matched is null AND incremental_hpd_u_matched is not null AND incremental_edc_u_matched is null
THEN units - incremental_hpd_u_matched
WHEN dob_u_matched is not null AND incremental_hpd_u_matched is null AND incremental_edc_u_matched is not null
THEN units - dob_u_matched - incremental_edc_u_matched
WHEN dob_u_matched is not null AND incremental_hpd_u_matched is not null AND incremental_edc_u_matched is null
THEN units - dob_u_matched - incremental_hpd_u_matched
WHEN dob_u_matched is not null AND incremental_hpd_u_matched is null AND incremental_edc_u_matched is null
THEN units - dob_u_matched END)

-- Check units remaining has been calculated for all projects with units
SELECT * FROM capitalplanning.all_possible_projects
WHERE remaining_dcp_units is null
AND manual_exclude <> 0

/**Zero if units remaining is negative or 10 or fewer units**/
-- *Not surprising to see negative units as DCP portion may not be entire project or development plans can change
-- *Total of 111 positive units remaining zeroed unit
UPDATE capitalplanning.all_possible_projects
SET remaining_dcp_units = 0
WHERE remaining_dcp_units <=10 
